

# get categories

require 'open-uri'
require 'nokogiri'
require 'json'

BASE_URI = 'http://technology.nasa.gov'

def get_category_query_terms
	category_query_terms = []
	doc = Nokogiri::HTML open("http://technology.nasa.gov/patents")
	categories = doc.css "div#vpp a"
	categories.each do |node|
		category_query_term = node["href"].gsub("_"," ").gsub("/","")
		category_query_terms << URI.escape(category_query_term)
	end
	category_query_terms
end

def parse_patent_ids_from_page(category_link, page = 0, patent_ids = [])
	uri = BASE_URI + "/svr/search.php?r=category&d=patent&q=#{category_link}&p=#{page.to_s}"
	response = JSON.parse(open(uri).read)
	if response["results"].count > 0
		puts "Scraping IDs for page #{page}"
		response["results"].each do |result|
			patent_ids << result[4]
		end
		# page += 1
		# parse_patent_ids_from_page(category_link, page, patent_ids)
	end
	patent_ids
end

def get_patent_details(patent_id)
	uri = BASE_URI + "/svr/search.php?d=patent&r=geturl&q=#{patent_id}"
	response = JSON.parse(open(uri).read)
	response
end


patent = get_patent_details("patent_LAR-18143-1")["results"]
puts patent["category"]
puts patent["abstract"]

# links = get_category_query_terms
# puts parse_patent_ids_from_page(links.first)

# get_categories
# parse_page_of_links