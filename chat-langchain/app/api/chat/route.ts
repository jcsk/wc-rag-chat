// JS backend not used by default, see README for instructions.

import { NextRequest, NextResponse } from "next/server";

import type { BaseLanguageModel } from "langchain/base_language";
import type { Document } from "langchain/document";
import type { BaseRetriever } from "langchain/schema/retriever";

import { RunnableSequence, RunnableMap } from "langchain/schema/runnable";
import { HumanMessage, AIMessage, BaseMessage } from "langchain/schema";
import { ChatOpenAI } from "langchain/chat_models/openai";
import { StringOutputParser } from "langchain/schema/output_parser";
import { PromptTemplate, ChatPromptTemplate, MessagesPlaceholder } from "langchain/prompts";

import weaviate from "weaviate-ts-client";
import { WeaviateStore } from "langchain/vectorstores/weaviate";
import { OpenAIEmbeddings } from "langchain/embeddings/openai";

export const runtime = "edge";

const RESPONSE_TEMPLATE = `You are an expert in Napa Valley and all things related to wine country, tasked to answer any question about Napa Valley. Using the provided context, answer the user's question to the best of your ability using the resources provided.
Generate a comprehensive and informative answer (but no more than 80 words) for a given question based solely on the provided search results (URL and content). You must only use information from the provided search results. Use an unbiased and journalistic tone. Combine search results together into a coherent answer. Do not repeat text. Cite search results using [\${{number}}] notation. Only cite the most relevant results that answer the question accurately. Place these citations at the end of the sentence or paragraph that reference them - do not put them all at the end. If different results refer to different entities within the same name, write separate answers for each entity. At the end of the response, come up with a question that is a reasonable followup question to the user's question and context gathered.
If there is nothing in the context relevant to the question at hand, just say "Hmm, I'm not sure." Don't try to make up an answer.
Anything between the following \`context\`  html blocks is retrieved from a knowledge bank, not part of the conversation with the user.

<context>
    {context}
<context/>

REMEMBER: If there is no relevant information within the context, just say "Hmm, I'm not sure." Don't try to make up an answer. Anything between the preceding 'context' html blocks is retrieved from a knowledge bank, not part of the conversation with the user.
`;

const REPHRASE_TEMPLATE = `Given the following conversation and a follow up question, rephrase the follow up question to be a standalone question.

Chat History:
{chat_history}
Follow Up Input: {question}
Standalone Question:`;

const getRetriever = async () => {
  const client = weaviate.client({
    scheme: "https",
    host: process.env.WEAVIATE_HOST!,
    apiKey: new weaviate.ApiKey(
      process.env.WEAVIATE_API_KEY!
    ),
  });
  const vectorstore = await WeaviateStore.fromExistingIndex(new OpenAIEmbeddings({}), {
    client,
    indexName: process.env.WEAVIATE_INDEX_NAME!,
    textKey: "text",
    metadataKeys: ["source", "title"],
  });
  return vectorstore.asRetriever({ k: 6 });
};

const createRetrieverChain = (llm: BaseLanguageModel, retriever: BaseRetriever, useChatHistory: boolean) => {
  if (!useChatHistory) {
    return RunnableSequence.from([
      ({ question }) => question,
      retriever
    ]);
  } else {
    const CONDENSE_QUESTION_PROMPT = PromptTemplate.fromTemplate(REPHRASE_TEMPLATE);
    const condenseQuestionChain = RunnableSequence.from([
      CONDENSE_QUESTION_PROMPT,
      llm,
      new StringOutputParser()
    ]).withConfig({
      tags: ["CondenseQuestion"]
    });
    return condenseQuestionChain.pipe(retriever);
  }
};

const formatDocs = (docs: Document[]) => {
  return docs.map((doc, i) => `<doc id='${i}'>${doc.pageContent}</doc>`).join("\n");
};

const formatChatHistoryAsString = (history: BaseMessage[]) => {
  return history.map((message) => `${message._getType()}: ${message.content}`).join('\n');
}

const createChain = (llm: BaseLanguageModel, retriever: BaseRetriever, useChatHistory: boolean) => {
  const retrieverChain = createRetrieverChain(llm, retriever, useChatHistory).withConfig({ tags: ["FindDocs"] });
  const context = new RunnableMap({
    steps: {
      context: RunnableSequence.from([
        ({question, chat_history}) => ({question, chat_history: formatChatHistoryAsString(chat_history)}),
        retrieverChain,
        formatDocs
      ]),
      question: ({ question }) => question,
      chat_history: ({ chat_history }) => chat_history
    }
  }).withConfig({ tags: ["RetrieveDocs"] });
  const prompt = ChatPromptTemplate.fromMessages([
    ["system", RESPONSE_TEMPLATE],
    new MessagesPlaceholder("chat_history"),
    ["human", "{question}"],
  ]);

  const responseSynthesizerChain = prompt.pipe(llm).pipe(new StringOutputParser()).withConfig({
    tags: ["GenerateResponse"],
  });
  return context.pipe(responseSynthesizerChain);
}

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const question = body.message;
    const chatHistory = (Array.isArray(body.history) && body.history) ?? [];
    const conversationId = body.conversation_id;

    if (question === undefined || typeof question !== "string") {
      return NextResponse.json({ error: `Invalid "message" parameter.` }, { status: 400 });
    }

    const convertedChatHistory = [];
    for (const historyMessage of chatHistory) {
      if (historyMessage.human) {
        convertedChatHistory.push(new HumanMessage({ content: historyMessage.human }));
      } else if (historyMessage.ai) {
        convertedChatHistory.push(new AIMessage({ content: historyMessage.ai }));
      }
    }

    const metadata = { conversation_id: conversationId };
    const llm = new ChatOpenAI({
      modelName: "gpt-3.5-turbo-16k",
      temperature: 0,
    });
    const retriever = await getRetriever();
    const answerChain = createChain(llm, retriever, !!convertedChatHistory.length);

    // Narrows streamed log output down to final output and the FindDocs tagged chain to
    // selectively stream back sources.
    const stream = await answerChain.streamLog({
      question,
      chat_history: convertedChatHistory,
    }, {
      metadata
    }, {
      includeTags: ["FindDocs"],
    });

    // Only return a selection of output to the frontend
    const textEncoder = new TextEncoder();
    const clientStream = new ReadableStream({
      async pull(controller) {
        const { value, done } = await stream.next();
        if (done) {
          controller.close();
        } else if (value) {
          let hasEnqueued = false;
          for (const op of value.ops) {
            if ("value" in op) {
              if (op.path === "/logs/0/final_output" && Array.isArray(op.value.output)) {
                const allSources = op.value.output.map((doc: Document) => {
                  return {
                    url: doc.metadata.source,
                    title: doc.metadata.title,
                  }
                });
                if (allSources.length) {
                  const chunk = textEncoder.encode(JSON.stringify({ sources: allSources }) + "\n");
                  controller.enqueue(chunk);
                  hasEnqueued = true;
                }
              } else if (op.path === "/streamed_output/-") {
                const chunk = textEncoder.encode(JSON.stringify({tok: op.value}) + "\n");
                controller.enqueue(chunk);
                hasEnqueued = true;
              } else if (op.path === "" && op.op === "replace") {
                const chunk = textEncoder.encode(JSON.stringify({run_id: op.value.id}) + "\n");
                controller.enqueue(chunk);
                hasEnqueued = true;
              }
            }
          }
          // Pull must always enqueue a value
          if (!hasEnqueued) {
            controller.enqueue(textEncoder.encode(""));
          }
        }
      },
    });

    return new Response(clientStream);
  } catch (e: any) {
    console.log(e);
    return NextResponse.json({ error: e.message }, { status: 500 });
  }
}
