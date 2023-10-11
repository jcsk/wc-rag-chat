###
### steps in ingest NV, SV, WC content
##

# sitemaps
# pull out URLS

require 'open-uri'
require 'nokogiri'

def scrape_text_between_header_and_footer(url)
  html_content = URI.open(url).read
  doc = Nokogiri::HTML(html_content)

  header = doc.css('.header').first
  footer = doc.css('.footer').first

  return "Header or footer not found" unless header && footer

  all_nodes = header.parent.children
  in_between_nodes = all_nodes.slice((all_nodes.index(header) + 1)...all_nodes.index(footer))

  text_content = in_between_nodes.map do |node|
    text = node.text.gsub(/\s+/, ' ').strip
    text unless text.empty?
  end.compact.join("\n").strip

  text_content = text_content.gsub(/\n{2,}/, "\n")
  text_content = text_content.gsub(/(jQuery\(\w+[\s\S]*?\);)|(googletag\.\w+[\s\S]*?\);)|(<.*?>)/, "")
  text_content = text_content.sub(/Recently Viewed.*/m, '')
  text_content = text_content.sub(/^\/\.header/, '')
  text_content = text_content.sub(/\n× EXPERIENCES[\s\S]*?\nmodal\n \}\);/, '')
  text_content = text_content.gsub(/× Shop COVET PASS[\s\S]*?Get The Newsletter/, '')
  text_content = text_content.gsub(/× COVET PASS[\s\S]*?Get The Newsletter/, '')

  unwanted_strings = [
    '/.header',
    '/.intro',
    /\n× EXPERIENCES COVET PASS.+\nmodal\n/,
    /\/.wrapper[\s\S]*/, # This regex will match '/ .wrapper' and everything after it
    /var [^\n]+;/,
    /function\([^\n]+\)\s?\{[^\n]+\};/,
    /(?:\/\*(?:[\s\S]*?)\*\/)|(?:([\s;])+\/\/(?:.*)?)/,
    /body\s?\.[^\n]+\{[^\n]+\}/,
    /See What’s Open Guides[\s\S]*WineCountry Media, LLC. All rights reserved\./
  ]

  unwanted_strings.each do |str|
    text_content.gsub!(str, '')
  end

  # Cleaning up HTML tags and JavaScript with Sanitize
  text_content = Sanitize.clean(text_content, :remove_contents => ['script', 'style'])
  text_content
end


def scrape_additional_data(url)
  doc = Nokogiri::HTML(URI.open(url))

  title = doc.title
  #title_element = doc.at_css('.blog-title') || doc.at_css('.intro-head-title h1')
  #title = title_element ? title_element.text.strip : "Unknown Title"

  author_element = doc.at_css('.author') || doc.at_css('.intro-head-meta li:nth-child(2)')
  date_element = doc.at_css('.date') || doc.at_css('.intro-head-meta li:nth-child(3)')

  author = author_element ? author_element.text.strip : "Unknown Author"
  date = date_element ? date_element.text.strip : "Unknown Date"

  images = doc.css('.wpb_single_image img').map { |img| img['src'] }

  [title, author, date, images]
end

#/Users/jeffreykrause/Downloads
BlogPost.delete_all
bad_urls = Array.new

File.readlines('/Users/jeffreykrause/Downloads/all_extracted_urls.txt').each do |url|
#File.readlines('/Users/jeffreykrause/Downloads/all_extracted_urls.txt').sample(10).each do |url|
    url = url.strip
    #puts url
    # Check if a BlogPost with the current URL already exists
    if BlogPost.exists?(url: url)
      puts "Skipping #{url} - already exists in the database."
      next
    end

    puts "Processing #{url}"

    begin
      full_content = scrape_text_between_header_and_footer(url)

      title, author, date, images = scrape_additional_data(url)

      # Assuming you have a model BlogPost with ActiveRecord and corresponding attributes
      BlogPost.create!(
        title: title,
        article_date: date,
        author: author,
        content: full_content,
        url: url,
        site: URI.parse(url).host,
        images: images.join(", ")
      )

      puts "Processed #{url}"

    rescue StandardError => e
      puts "Failed to process #{url}: #{e.message}"
      bad_urls.push(url)
    end
  end;0



urls = [
"https://www.sonoma.com/event/drive-in-movie-night-at-notre-vue-estate-winery-vineyards/",
"https://www.sonoma.com/event/summer-sundays-at-notre-vue-estate-winery-vineyards-4/",
"https://www.sonoma.com/event/summer-sundays-at-notre-vue-estate-winery-vineyards-3/",
"https://www.sonoma.com/event/4th-of-july-red-white-rose-at-muscardini-cellars/",
"https://www.sonoma.com/event/4th-of-july-hometown-parade-footrace-at-kenwood-park/"

  ]


# Loop through URLs and print scraped content
urls.each do |url|
  puts "Scraping: #{url}"
  result = scrape_text_between_header_and_footer(url)
  puts result
  puts "-" * 80  # Output separator
end

#### replace content



modal
&lt; Back to event calendar | Home / Events calendar
Fairmont Sonoma Mission Inn’s Winemaker Dinner Series September 28, 2022 @ 6:00 pm - 8:00 pm | $150 per person Event Navigation « Comedian Pauline Yasuda at Deerfield Ranch Winery Wine &amp; Sunset Series at Paradise Ridge Winery » This event has passed. Event Categories: Dining, Food and Wine Pairing, Sonoma County, Wine Tasting Wine Grower Dinner, Harvest Celebration – A Tribute to Phil Coturri Executive Chef Jared Reeves in partnership with some of the region’s most renowned winemakers have come together for a series of dinners you won’t want to miss. Kick off the evening with a sparkling wine reception followed by a 4-course wine paired dinner hosted under our historic Water Tower. Limited seating available. Pricing varies per dinner and excludes tax and gratuity. For reservations and/or further information please contact: Resort Reservations at 707-939-2415 or via email at Smi.resortreservations.dl@fairmont.com Venue The Fairmont Sonoma Mission Inn 100 Boyes Blvd., Sonoma, CA 95476 United States Google Calendar iCal / Outlook Export Details September 28, 2022 @ 6:00 pm - 8:00 pm Cost: $150 per person Related Categories : Dining, Food and Wine Pairing, Sonoma County, Wine Tasting Website https://www.fairmont.com/sonoma/activities/smi-winemaker-dinner/?_ga=2.253689935.754853074.1664153300-2023554427.1663958875 Related Events October 3 Food Pizza and Pinot at… SONOMA’S POPULAR PIZZA AND WINE EXPERIENCE IS BACK! A collaborative culinary effort, Folktable Catering provides… October 7 Outdoors Annual Harvest Fall Hike… Join Benziger Family Winery for their annual Harvest Hike, and take in the beauty of… October 14 Fairs &amp; Festivals Sonoma County Harvest Fair:… The epicenter of the Harvest Fair is still the Tasting Pavilion, featuring innovative cuisine paired… October 15 Fairs &amp; Festivals Healdsburg Crush: Pouring on… Join us for the ONLY wine tasting event that takes place on the Healdsburg Plaza!… Previous Event Listing Comedian Pauline Yasuda at Deerfield Ranch Winery Next Event Listing Wine &amp; Sunset Series at Paradise Ridge Winery GET TO KNOWNorthern Sonoma County Central Sonoma County Southern Sonoma County Coastal Sonoma County EXPLORE

# clean up content

SELECT * FROM blog_posts WHERE content like '

modal
&lt; Back to event calendar | Home / Events calendar%';

UPDATE blog_posts
SET content = REPLACE(content, E'

modal
&lt; Back to event calendar | Home / Events calendar', '')
 WHERE content like '

modal
&lt; Back to event calendar | Home / Events calendar%';

SELECT * FROM blog_posts WHERE content like '% GET TO KNOWNorthern Sonoma County Central Sonoma County Southern Sonoma County Coastal Sonoma County EXPLORE%';

UPDATE blog_posts
SET content = REPLACE(content, E' GET TO KNOWNorthern Sonoma County Central Sonoma County Southern Sonoma County Coastal Sonoma County EXPLORE', '')
 WHERE content like '% GET TO KNOWNorthern Sonoma County Central Sonoma County Southern Sonoma County Coastal Sonoma County EXPLORE%';


 ####
 ####
 ####

 ####
 #### experiment in entering my own text and url
 ####



 class CustomDoc:
     def __init__(self, source, text, title):
         self.source = source
         self.page_content = text
         self.title = title
         self.metadata = {
             "source": source,
             "title": title,
             # Add other metadata fields if needed
         }


 custom_data = [
     {
         "source": "https://www.napavalley.com/?s=book+a+hotel",
         "text": "At Napavalley.com you can book a hotel directly through us. This is better than booking through a travel service.  \
         You can get special deals through us for lots of Napa Valley hotels. Booking through us is great for our partners \
         and for you. You'll get extra special VIP treatment.",
         "title": "Booking a Hotel at Napa Valley",
     }
 ]

 custom_data_objects = [CustomDoc(**data) for data in custom_data]
 text_splitter = RecursiveCharacterTextSplitter(chunk_size=4000, chunk_overlap=200)
 docs_transformed = text_splitter.split_documents(custom_data_objects)


 client = weaviate.Client(
     url=WEAVIATE_URL,
     auth_client_secret=weaviate.AuthApiKey(api_key=WEAVIATE_API_KEY),
 )

 embedding = OpenAIEmbeddings(chunk_size=200)  # rate limit
 vectorstore = Weaviate(
     client=client,
     index_name="LangChain_agent_docs",
     text_key="text",
     embedding=embedding,
     by_text=False,
     attributes=["source", "title"],
 )

 #from langchain.indexes import SQLRecordManager

 record_manager = SQLRecordManager(
     f"weaviate/{WEAVIATE_DOCS_INDEX_NAME}", db_url=RECORD_MANAGER_DB_URL
 )
 record_manager.create_schema()

 #from langchain.indexes import index

 indexing_stats = index(
     docs_transformed,
     record_manager,
     vectorstore,
     cleanup="full",
     source_id_key="source",
 )


 ###
 ### delete

 vectorstore.delete(["96bc381a-665c-5113-8213-a1ec4072006c"])
 #record_manager.delete_records(["96bc381a-665c-5113-8213-a1ec4072006c"])
 connection = record_manager.connection

 delete_stmt = "DELETE FROM records WHERE id = :id"
 connection.execute(delete_stmt, {"id": "96bc381a-665c-5113-8213-a1ec4072006c"})

###
### business details loop through json
###

"""Load html from files, clean up, split, ingest into Weaviate."""
import logging
import os
import re
from parser import langchain_docs_extractor

import weaviate
from bs4 import BeautifulSoup, SoupStrainer
from langchain.document_loaders import RecursiveUrlLoader, SitemapLoader
from langchain.embeddings import OpenAIEmbeddings
from langchain.indexes import SQLRecordManager, index
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain.utils.html import PREFIXES_TO_IGNORE_REGEX, SUFFIXES_TO_IGNORE_REGEX
from langchain.vectorstores import Weaviate

from constants import WEAVIATE_DOCS_INDEX_NAME

logger = logging.getLogger(__name__)

WEAVIATE_URL = os.environ["WEAVIATE_URL"]
WEAVIATE_API_KEY = os.environ["WEAVIATE_API_KEY"]
RECORD_MANAGER_DB_URL = os.environ["RECORD_MANAGER_DB_URL"]

class CustomDoc:
   def __init__(self, source, text, title):
       self.source = source
       self.page_content = text
       self.title = title
       self.metadata = {
           "source": source,
           "title": title,
           # Add other metadata fields if needed
       }



import json
# (other imports you've mentioned...)

# Load the JSON file
with open("/Users/jeffreykrause/Downloads/business_details.json", "r") as file:
   business_data = json.load(file)

# Transform the data
transformed_data = [
   {
       "source": entry["source"],
       "text": entry["page_content"],
       "title": entry["title"],
   }
   for entry in business_data
]

custom_data_objects = [CustomDoc(**data) for data in transformed_data]

# Process the Transformed Data
text_splitter = RecursiveCharacterTextSplitter(chunk_size=4000, chunk_overlap=200)
docs_transformed = text_splitter.split_documents(custom_data_objects)

client = weaviate.Client(
   url=WEAVIATE_URL,
   auth_client_secret=weaviate.AuthApiKey(api_key=WEAVIATE_API_KEY),
)

embedding = OpenAIEmbeddings(chunk_size=200)  # rate limit
vectorstore = Weaviate(
   client=client,
   index_name="LangChain_agent_docs",
   text_key="text",
   embedding=embedding,
   by_text=False,
   attributes=["source", "title"],
)

#from langchain.indexes import SQLRecordManager

record_manager = SQLRecordManager(
   f"weaviate/{WEAVIATE_DOCS_INDEX_NAME}", db_url=RECORD_MANAGER_DB_URL
)
record_manager.create_schema()

#from langchain.indexes import index

indexing_stats = index(
   docs_transformed,
   record_manager,
   vectorstore,
   cleanup="full",
   source_id_key="source",
)


####
#### ingest blogs and site content
####
import logging
import os
import re
from parser import langchain_docs_extractor
import weaviate
from bs4 import BeautifulSoup, SoupStrainer
from langchain.document_loaders import RecursiveUrlLoader, SitemapLoader
from langchain.embeddings import OpenAIEmbeddings
from langchain.indexes import SQLRecordManager, index
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain.utils.html import PREFIXES_TO_IGNORE_REGEX, SUFFIXES_TO_IGNORE_REGEX
from langchain.vectorstores import Weaviate

from constants import WEAVIATE_DOCS_INDEX_NAME

logger = logging.getLogger(__name__)

WEAVIATE_URL = os.environ["WEAVIATE_URL"]
WEAVIATE_API_KEY = os.environ["WEAVIATE_API_KEY"]
RECORD_MANAGER_DB_URL = os.environ["RECORD_MANAGER_DB_URL"]

class CustomDoc:
   def __init__(self, source, text, title):
       self.source = source
       self.page_content = text
       self.title = title
       self.metadata = {
           "source": source,
           "title": title,
           # Add other metadata fields if needed
       }



import json
# (other imports you've mentioned...)

# Load the JSON file
with open("/Users/jeffreykrause/Downloads/blog_posts.json", "r") as file:
   business_data = json.load(file)

# Transform the data
transformed_data = [
   {
       "source": entry["url"],
       "text": entry["content"],
       "title": entry["title"],
   }
   for entry in business_data
]

custom_data_objects = [CustomDoc(**data) for data in transformed_data]

# Process the Transformed Data
text_splitter = RecursiveCharacterTextSplitter(chunk_size=4000, chunk_overlap=200)
docs_transformed = text_splitter.split_documents(custom_data_objects)

client = weaviate.Client(
   url=WEAVIATE_URL,
   auth_client_secret=weaviate.AuthApiKey(api_key=WEAVIATE_API_KEY),
)

embedding = OpenAIEmbeddings(chunk_size=200)  # rate limit
vectorstore = Weaviate(
   client=client,
   index_name="LangChain_agent_docs",
   text_key="text",
   embedding=embedding,
   by_text=False,
   attributes=["source", "title"],
)

#from langchain.indexes import SQLRecordManager

record_manager = SQLRecordManager(
   f"weaviate/{WEAVIATE_DOCS_INDEX_NAME}", db_url=RECORD_MANAGER_DB_URL
)
record_manager.create_schema()

#from langchain.indexes import index

indexing_stats = index(
   docs_transformed,
   record_manager,
   vectorstore,
   cleanup=None,
   source_id_key="source",
)

###
### business details loop from napawineproject.com
###

"""Load html from files, clean up, split, ingest into Weaviate."""
import logging
import os
import re
from parser import langchain_docs_extractor

import weaviate
from bs4 import BeautifulSoup, SoupStrainer
from langchain.document_loaders import RecursiveUrlLoader, SitemapLoader
from langchain.embeddings import OpenAIEmbeddings
from langchain.indexes import SQLRecordManager, index
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain.utils.html import PREFIXES_TO_IGNORE_REGEX, SUFFIXES_TO_IGNORE_REGEX
from langchain.vectorstores import Weaviate

from constants import WEAVIATE_DOCS_INDEX_NAME

logger = logging.getLogger(__name__)

WEAVIATE_URL = os.environ["WEAVIATE_URL"]
WEAVIATE_API_KEY = os.environ["WEAVIATE_API_KEY"]
RECORD_MANAGER_DB_URL = os.environ["RECORD_MANAGER_DB_URL"]

class CustomDoc:
   def __init__(self, source, text, title):
       self.source = source
       self.page_content = text
       self.title = title
       self.metadata = {
           "source": source,
           "title": title,
           # Add other metadata fields if needed
       }



import json
# (other imports you've mentioned...)

# Load the JSON file
with open("/Users/jeffreykrause/Downloads/business_details4.json", "r") as file:
   business_data = json.load(file)

# Transform the data
transformed_data = [
   {
       "source": entry["source"],
       "text": entry["page_content"],
       "title": entry["title"],
   }
   for entry in business_data
]

custom_data_objects = [CustomDoc(**data) for data in transformed_data]

# Process the Transformed Data
text_splitter = RecursiveCharacterTextSplitter(chunk_size=4000, chunk_overlap=200)
docs_transformed = text_splitter.split_documents(custom_data_objects)

client = weaviate.Client(
   url=WEAVIATE_URL,
   auth_client_secret=weaviate.AuthApiKey(api_key=WEAVIATE_API_KEY),
)

embedding = OpenAIEmbeddings(chunk_size=200)  # rate limit
vectorstore = Weaviate(
   client=client,
   index_name="LangChain_agent_docs",
   text_key="text",
   embedding=embedding,
   by_text=False,
   attributes=["source", "title"],
)

#from langchain.indexes import SQLRecordManager

record_manager = SQLRecordManager(
   f"weaviate/{WEAVIATE_DOCS_INDEX_NAME}", db_url=RECORD_MANAGER_DB_URL
)
record_manager.create_schema()

#from langchain.indexes import index

indexing_stats = index(
   docs_transformed,
   record_manager,
   vectorstore,
   cleanup=None,
   source_id_key="source",
)
