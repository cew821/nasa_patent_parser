

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

def parse_patent_ids_from_page(category_link, page = 0)
	patent_ids = []
	uri = BASE_URI + "/svr/search.php?r=category&d=patent&q=#{category_link}&p=#{page.to_s}"
	response = JSON.parse(open(uri).read)
	if response["results"].count > 0
		response["results"].each do |result|
			patent_ids << result[4]
		end
	end
	patent_ids
end


# puts get_patent_links("materials and coatings")["results"][2]

links = get_category_query_terms
puts parse_patent_ids_from_page(links.first)

# get_categories
# parse_page_of_links