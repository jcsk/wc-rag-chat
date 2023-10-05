import { MouseEvent, MouseEventHandler } from "react";
import { Heading, Link, Card, CardHeader, Flex, Spacer } from "@chakra-ui/react";
import { ExternalLinkIcon } from '@chakra-ui/icons'

export function EmptyState(props: {
  onChoice: (question: string) => any
}) {
  const handleClick = (e: MouseEvent) => {
    props.onChoice((e.target as HTMLDivElement).innerText);
  }
  return (
    <div className="rounded flex flex-col items-center max-w-full md:p-8">
      <Heading fontSize="3xl" fontWeight={"medium"} mb={1} color={"white"}>Chat Napa Valley</Heading>
      <Heading fontSize="xl" fontWeight={"normal"} mb={1} color={"white"} marginTop={"10px"} textAlign={"center"}>Ask me anything about Wine Country{" "}
      <Link href='https://www.napavalley.com/' color={"blue.200"}>
        Napa Valley!
      </Link></Heading>
      <Flex marginTop={"25px"} grow={1} maxWidth={"800px"} width={"100%"}>
        <Card onMouseUp={handleClick} width={"48%"}  backgroundColor={"rgb(58, 58, 61)"} _hover={{"backgroundColor": "rgb(78,78,81)"}} cursor={"pointer"} justifyContent={"center"}>
          <CardHeader justifyContent={"center"}>
            <Heading fontSize="lg" fontWeight={"medium"} mb={1} color={"gray.200"} textAlign={"center"}>What are some extreme adventures to do in Napa Valley?</Heading>
          </CardHeader>
        </Card>
        <Spacer />
        <Card onMouseUp={handleClick} width={"48%"}  backgroundColor={"rgb(58, 58, 61)"} _hover={{"backgroundColor": "rgb(78,78,81)"}} cursor={"pointer"} justifyContent={"center"}>
          <CardHeader justifyContent={"center"}>
            <Heading fontSize="lg" fontWeight={"medium"} mb={1} color={"gray.200"} textAlign={"center"}>What is Pinot Noir?</Heading>
          </CardHeader>
        </Card>
      </Flex>
      <Flex marginTop={"25px"} grow={1} maxWidth={"800px"} width={"100%"}>
        <Card onMouseUp={handleClick} width={"48%"}  backgroundColor={"rgb(58, 58, 61)"} _hover={{"backgroundColor": "rgb(78,78,81)"}} cursor={"pointer"} justifyContent={"center"}>
          <CardHeader justifyContent={"center"}>
            <Heading fontSize="lg" fontWeight={"medium"} mb={1} color={"gray.200"} textAlign={"center"}>What is the weather like in napa valley in October?</Heading>
          </CardHeader>
        </Card>
        <Spacer />
        <Card onMouseUp={handleClick} width={"48%"}  backgroundColor={"rgb(58, 58, 61)"} _hover={{"backgroundColor": "rgb(78,78,81)"}} cursor={"pointer"} justifyContent={"center"}>
          <CardHeader justifyContent={"center"}>
            <Heading fontSize="lg" fontWeight={"medium"} mb={1} color={"gray.200"} textAlign={"center"}>How do I book a hotel?</Heading>
          </CardHeader>
        </Card>
      </Flex>
    </div>
  );
}
