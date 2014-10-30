

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
	response = JSON.parse(open(uri).read)["results"]
	puts "retrieved patent #{patent_id} with results #{response}"
	PatentData.new(response)
end


class PatentData
	attr_reader :category, :abstract, :title, :reference_number, :center, :patent_number, :serial_number, :expiration_date, :contact_info

	def initialize(json)
		@category = json["category"]
		@abstract = abstract_cleanser(json["abstract"])
		@title = json["title"]
		@reference_number = json["reference_number"]
		@center = json["center"]
		@patent_number = json["patent_number"]
		@serial_number = json["serial_number"]
		@expiration_date = json["expiration_date"]
		@contact_info = "TBD"
	end

	private
		def abstract_cleanser(abstract_raw_text)
			abstract_raw_text.gsub!(/[-]*as filed in application[ s:-]*/i,'')
			abstract_raw_text.gsub!(/[-]*as filed in patent application[s:-]*/i,'')
			abstract_raw_text.gsub!(/[-]*as filed in the patent application[s:-]*/i,'')
			abstract_raw_text.gsub!(/[-]*patent application as filed[:-]*/i,'')
			abstract_raw_text.gsub!(/-------------------------------[-]*/,'')
			abstract_raw_text.gsub!(/[-]*as filed[-]*/i,'')
			
			abstract_raw_text
		end

		def get_contact_info_from_center(center)
			ContactInfo = Struct.new :facility, :office, :address1, :address2, :city_state_zip, :contact_name, :contact_email, :contact_phone

			contact = ContactInfo.new

			case center
			when 'arc'
				contact.facility = "NASA Ames Research Center"
				contact.office = "Technology Partnerships Division"
				contact.address1 = "Mail Stop 202A-3"
				contact.city_state_zip = "Moffett Field, CA 94035"
				contact.contact_name = "Trupti D. Sanghani"
				contact.contact_email = "Trupti.D.Sanghani@nasa.gov"
			when 'dfrc'
				contact.facility = "NASA Armstrong IPO Office"
				contact.contact_email = "DFRC-Technology@mail.nasa.gov"
			when 'grc'
				contact.facility = "NASA Glenn Research Center"
				contact.office = "Innovation Projects Office"
				contact.contact_email = "ttp@grc.nasa.gov"
			when 'gsfc'
				contact.facility = "NASA Goddard Space Flight Center"
				contact.office = "Innovative Partnerships Program Office"
				contact.address1 = "Code 504"
				contact.city_state_zip = "Greenbelt, MD 20771"
				contact.contact_phone = "(301) 286-5810"
				contact.contact_email = "techtransfer@gsfc.nasa.gov"
			when 'hdqs'
				contact.facility = "NASA Headquarters"
				contact.address1 = "Washington, DC 20546-1000"
				contact.contact_name = "Daniel Lockney"
				contact.contact_email = "Daniel.P.Lockney@nasa.gov"
				contact.contact_phone = "(202) 358-2037"
			when 'jpl'
				contact.facility = "NASA Jet Propulsion Laboratory"
				contact.office = "California Institute of Technology"
				contact.address1 = 
				contact.address2 =
				contact.city_state_zip = 
				contact.contact_name =
				contact.contact_email = 
				contact.contact_phone = 




     #     case "jpl":
     #        contact  = '<div class="contact">';
     #        contact += '<br />';
     #        contact += '<br />';
     #        contact += 'Mail Stop JPL:8200<br />';
     #        contact += '4800 Oak Grove Drive<br />';
     #        contact += 'Pasadena, CA 91109<br/><br />';
     #        contact += 'Debora Wolfenbarger<br />';
     #        contact += 'Phone: (818) 354-3829<br />';
     #        contact += '<a href="mailto:Debora.L.Wolfenbarger@nasa.gov">Debora.L.Wolfenbarger@nasa.gov</a>';
     #        contact += '</div>';
     #        break;
     #     case "jsc":
     #        contact = '<div class="contact">';
     #        contact += 'NASA Johnson Space Center<br/>';
     #        contact += 'Technology Transfer and Commercialization Office (TTO)<br/>';
     #        contact += '2101 NASA Parkway<br/>';
     #        contact += 'Mail Code: AO5 <br/>';
     #        contact += 'Houston, Texas 77058<br/><br/>';
     #        contact += 'Phone: (281) 483-3809<br/>';
     #        contact += '<a href="mailto:jsc-techtran@mail.nasa.gov">jsc-techtran@mail.nasa.gov</a>';
     #        contact += '</div>';
     #        break;
     #     case "ksc":
     #        contact = '<div class="contact">';
     #        contact += 'NASA Kennedy Space Center<br/>';
     #        contact += 'Innovative Partnerships Office<br/>';
     #        contact += 'Kennedy Space Center, FL 32899<br/><br/>';
     #        contact += 'Phone: (321) 861-7158<br/>';
     #        contact += '<a href="mailto:KSC-DL-TechnologyTransfer@mail.nasa.gov">KSC-DL-TechnologyTransfer@mail.nasa.gov</a>';
     #        contact += '</div>';
     #        break;
     #     case "larc":
     #        contact  = '<div class="contact">';
     #        contact += 'NASA Langley Research Center<br/>';
     #        contact += 'Office of Partnership Development<br/>';
     #        contact += 'MS 218<br/>';
     #        contact += 'Hampton, VA 23681-2199<br/><br/>';
     #        contact += 'Sandra Pretlow<br/>';
     #        contact += 'Phone: (757) 864-2358<br/>';
     #        contact += '<a href="mailto:Sandra.k.pretlow@nasa.gov">Sandra.K.Pretlow@nasa.gov</a>';
     #        contact += '</div>';
     #        break;
     #     case "msfc":
     #        contact = '<div class="contact">';
     #        contact += 'NASA Marshall Space Flight Center<br/>';
     #        contact += 'Technology Transfer Office<br/>';
     #        contact += 'Huntsville, AL 35812<br/><br/>';
     #        contact += 'Sammy Nabors<br/>';
     #        contact += 'Phone: (256) 544-5226<br/>';
     #        contact += '<a href="mailto:Sammy.Nabors@nasa.gov">Sammy.Nabors@nasa.gov</a>';
     #        contact += '</div>';
     #        break;
     #     case "ssc":
     #        contact = '<div class="contact">';
     #        contact += 'NASA John C. Stennis Space Center<br/>';
     #        contact += 'AA00/Office of the Center Chief Technologist <br/>';
     #        contact += 'Stennis Space Center, MS 39529<br/><br/>';
     #        contact += 'Phone: (228) 688-1929<br/>';
     #        contact += 'Fax: (228) 688-1156<br/>';
     #        contact += '<a href="mailto:SSC-technology@nasa.gov">SSC-technology@nasa.gov</a>';
     #        contact += '</div>';
     #        break;
     #     default:
     #        contact = '';
		end
end

patent = get_patent_details("patent_LAR-18143-1")
puts patent.inspect

# links = get_category_query_terms
# puts parse_patent_ids_from_page(links.first)

# get_categories
# parse_page_of_links