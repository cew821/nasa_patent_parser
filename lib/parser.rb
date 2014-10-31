

# get categories

require 'open-uri'
require 'nokogiri'
require 'json'
require 'csv'

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

def write_patent_details_to_csv(patents = [], filename = "patents.csv")
  CSV.open(filename, "w+") do |csv|
    csv << PatentData.headers
    patents.each do |patent|
      csv << patent.values
    end
  end
end


ContactInfo = Struct.new :facility, :office, :address1, :address2, :city_state_zip, :contact_name, :contact_email, :contact_phone

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
    @contact_info = get_contact_info_from_center(@center.downcase)
  end

  def values
    values = [@category, @abstract, @title, @reference_number, @center, @patent_number, @serial_number, @expiration_date]
    @contact_info.values.each { |v| values << v }
    values
  end

  def self.headers
    headers = ["Category", "Abstract", "Title", "Reference Number", "Center", "Patent Number", "Serial Number", "Expiration Date", "Facility", "Office", "Address1", "Address2", "City State Zip", "Contact Name", "Contact Email", "Contact Phone"]
  end

  private
  
    def abstract_cleanser(abstract_raw_text)
      # The abstract field returned by NASA's API includes text that is stripped out by NASA's portal.js before it is rendered; this functionality is ported here.

      abstract_raw_text.gsub!(/[-]*as filed in application[ s:-]*/i,'')
      abstract_raw_text.gsub!(/[-]*as filed in patent application[s:-]*/i,'')
      abstract_raw_text.gsub!(/[-]*as filed in the patent application[s:-]*/i,'')
      abstract_raw_text.gsub!(/[-]*patent application as filed[:-]*/i,'')
      abstract_raw_text.gsub!(/-------------------------------[-]*/,'')
      abstract_raw_text.gsub!(/[-]*as filed[-]*/i,'')
      abstract_raw_text
    end

    def get_contact_info_from_center(center)
      # patent contact info ported from the "Portal.js" file that powers technology.nasa.gov (available here: http://technology.nasa.gov/js/portal). Contact info ported from the get_pcon(c) function.
      
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
        contact.address1 = "Mail Stop JPL:8200"
        contact.address2 = "4800 Oak Grove Drive"
        contact.city_state_zip = "Pasadena, CA 91109"
        contact.contact_name = "Debora Wolfenbarger"
        contact.contact_email = "Debora.L.Wolfenbarger@nasa.gov"
        contact.contact_phone = "(818) 354-3829"
      when 'jsc'
        contact.facility = "NASA Johnson Space Center"
        contact.office = "Technology Transfer and Commercialization Office (TTO)"
        contact.address1 = "2101 NASA Parkway"
        contact.address2 = "Mail Code: AO5"
        contact.city_state_zip = "Houston, Texas 77058"
        contact.contact_phone = "(281) 483-3809" 
        contact.contact_email = "jsc-techtran@mail.nasa.gov"
      when 'ksc'
        contact.facility = "NASA Kennedy Space Center"
        contact.office = "Innovative Partnerships Office"
        contact.address1 = "Kennedy Space Center"
        contact.city_state_zip = "Kennedy Space Center, FL 32899"
        contact.contact_phone = "(321) 861-7158"
        contact.contact_email = "KSC-DL-TechnologyTransfer@mail.nasa.gov"
      when 'larc'
        contact.facility = "NASA Langley Research Center"
        contact.office = "Office of Partnership Development"
        contact.address1 = "MS 218"
        contact.city_state_zip = "Hampton, VA 23681-2199"
        contact.contact_name = "Sandra Pretlow"
        contact.contact_email = "Sandra.k.pretlow@nasa.gov"
        contact.contact_phone = "(757) 864-2358"
      when 'msfc'
        contact.facility = "NASA Marshall Space Flight Center"
        contact.office = "Technology Transfer Office"
        contact.city_state_zip = "Huntsville, AL 35812"
        contact.contact_name = "Sammy Nabors"
        contact.contact_phone = "(256) 544-5226"
        contact.contact_email = "Sammy.Nabors@nasa.gov"
      when 'ssc'
        contact.facility = "NASA John C. Stennis Space Center"
        contact.office = "AA00/Office of the Center Chief Technologist"
        contact.city_state_zip = "Stennis Space Center, MS 39529"
        contact.contact_phone = "(228) 688-1929"
        contact.contact_email = "SSC-technology@nasa.gov"
      end
      contact
    end
end

patent = get_patent_details("patent_LAR-18143-1")
patents = [patent]
write_patent_details_to_csv(patents)

# links = get_category_query_terms
# puts parse_patent_ids_from_page(links.first)

# get_categories
# parse_page_of_links