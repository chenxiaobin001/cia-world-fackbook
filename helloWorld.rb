=begin
  this is code for hw2\
  p1 finished, refactored
  p2 finished
  p3 finished
=end

require 'nokogiri'
require 'open-uri'
require 'uri'


# a class to record a country name and elevation point

class CountryElev
  include Comparable
  attr_accessor :country_name
  attr_accessor :country_elev_point

  def <=>(that)
    country_elev_point <=> that.country_elev_point
  end

  def initialize(country_name, country_elev_point)
    @country_name = country_name
    @country_elev_point = country_elev_point
  end

  def to_s()
    return (country_name.to_s + "  " + country_elev_point.to_s)
  end

end

class Latitude
  attr_accessor :ns
  attr_accessor :degree
  def initialize(ns, degree)
    @ns = ns
    @degree = degree
  end
  def to_s()
    return (degree.to_s + " " + ns.to_s)
  end
end

class Longitude
  attr_accessor :ew
  attr_accessor :degree
  def initialize(ew, degree)
    @ew = ew
    @degree = degree
  end
  def to_s()
    return (degree.to_s + " " + ew.to_s)
  end

end

class GeographicCoordinates
  attr_accessor :latitude
  attr_accessor :longitude
  def initialize(latitude, longitude)
    @latitude = latitude
    @longitude = longitude
  end
end

# a class to record country's name, URL, URL_doc

class CountryURL

  attr_accessor :country_name
  attr_accessor :country_URL
  attr_accessor :country_doc

  def initialize(country_name, country_URL, country_doc)
    @country_name = country_name
    @country_URL = country_URL
    @country_doc = country_doc    #store file as a string
  end

end


# a class to provide solutions

class Solution

  attr_accessor :CIA_URL
  attr_accessor :country_lists

  def initialize
    @country_lists = []
    @CIA_URL =  %Q|https://www.cia.gov/library/publications/the-world-factbook/print/textversion.html|
  end

  # get all countries in sorted order
  def get_all_countries
    puts "collecting countries infomation.."
    doc = Nokogiri::HTML(open(@CIA_URL))

    doc.css("ul#GetAppendix_TextVersion li a").each do |country|
      country_name = country.text
      next if country_name == "World"
      country_url =  @CIA_URL
      new_url = (country_url.split('/')[0..-2]).join('/')
      country_url = new_url << '/' << country['href']

      #   puts "#{country_name}"
      f = open(country_url)
      doc = f.read()
      f.close()
      @country_lists << (CountryURL.new(country_name, country_url, doc))
    end
  end

  # print all countries
  def print_all_countries
    @country_lists.each do |country|
      puts puts "#{country.country_name}\t#{}"
    end
  end

  def get_hemisphere(geographicCoordinates)
    latitude = geographicCoordinates.latitude
    longitude = geographicCoordinates.longitude
    result = ""
    if latitude.ns == "N"
      result << "north"
    else
      result << "south"
    end
    if (longitude.ew == "E" and longitude.degree < 160) or (longitude.ew == "W" and longitude.degree >= 20)
      result << "east"
    else
      result << "west"
    end
    return result
  end

  # check if contains certain word
  def str_include?(str, target_str)
    tmp = target_str.downcase
    if !!str.match(/#{tmp}/i)
      return true
    else
      return false
    end
  end

  #check if is belong to a continent
  def is_belong_to?(country, target_continent)
    my_html = Nokogiri::HTML(country.country_doc)
    doc = my_html.at("table tr td a[title = 'Notes and Definitions: Map references']")
    belong = false

    if doc != nil then
      if country.country_name == "France"    #due to html format inconsistence (corner case)
        return false
        doc.parent.parent.parent.next_element.css('span').each do |continent|
          #        puts continent.parent.text
          tmpstr = continent.text
          if str_include?(tmpstr, target_continent)
            #          puts "jajaja"
            belong = true
          end
        end
      else
        continent = doc.parent.parent.parent.next_element.at('a').text
        #      puts continent.downcase!
        if str_include?(continent, target_continent)
          #        puts "jajaja"
          belong = true
        end
      end
    end
    return belong
  end

  #search for natural hazards
  def s1_search_natural_hazards(target_continent, target_word)
    continent_country_lists = []
    puts "========================================================================"
    puts "getting countries in continent: '#{target_continent}'that are prone to natural hazard'#{target_word}':"

    @country_lists.each do |country|
      # check if this country  prone to earthquakes.
      if is_belong_to?(country, target_continent) == true
        my_html = Nokogiri::HTML(country.country_doc)
        doc = my_html.at("table tr td a[title='Notes and Definitions: Natural hazards']")
        if doc != nil
          hazard = doc.parent.parent.parent.next_element.at('div').text.to_s
          if str_include?(hazard, target_word)
            continent_country_lists << (country.country_name.to_s)
          end
        end
      end

    end
    continent_country_lists.each do |x|
      puts "#{x}   "
    end

    continent_country_lists
  end

  def s2_search_lowest_elevation_point(target_continent)
    country_list = []
    puts "========================================================================"
    puts "getting countries\' elevation point in continent: '#{target_continent}':"

    @country_lists.each do |country|
      if is_belong_to?(country, target_continent) == true
        my_html = Nokogiri::HTML(country.country_doc)
        doc = my_html.at("table tr td a[title='Notes and Definitions: Elevation extremes']")
        if doc != nil
          tmpText = doc.parent.parent.parent.next_element.at('div').text.to_s
          elev_point = (tmpText[/-?\d+/]).to_i
          country_list << (CountryElev.new(country.country_name.to_s, elev_point))
        end
      end
    end
=begin
      country_list.each do |c|
        puts c.to_s
      end
=end
    min_elevation = country_list.min()
    #    puts min_elevation.country_elev_point
    result_list = country_list.select{|x| x.country_elev_point == min_elevation.country_elev_point}

    puts "in continent: #{target_continent}, these countries have lowest elevation:"
    result_list.each do |c|
      puts c.to_s
    end
    puts "========================================================================"
  end

  def s3_search_hemisphere(hemisphere)
    puts "========================================================================"
    puts "east west line: 160E 20W"
    puts "north south line: equator"
    country_list = []
    puts "getting countries in'#{hemisphere}' hemisphere..."
    la = hemisphere[/south|north/i].to_s
    lo = hemisphere[/west|east/i].to_s
    geo = la + lo
    @country_lists.each do |country|
      my_html = Nokogiri::HTML(country.country_doc)
      doc = my_html.at("table tr td a[title='Notes and Definitions: Geographic coordinates']")
      if doc != nil
        tmpText = doc.parent.parent.parent.next_element.at('div').text.to_s.split(',')
        if tmpText != nil
          latitude = Latitude.new((tmpText[0][/[NS]/]).to_s, (tmpText[0][/\d+/]).to_i)
          longitude = Longitude.new((tmpText[1][/[EW]/]).to_s, (tmpText[0][/\d+/]).to_i)
     #     print latitude.to_s
     #     print longitude.to_s
          gc = GeographicCoordinates.new(latitude, longitude)
     #     puts get_hemisphere(gc)
          if !!get_hemisphere(gc).match(/#{geo}/i)
            country_list << country.country_name
          end
        end
      end
    end
    country_list.each { |c| puts c.to_s}
    country_list
  end

  def s4_search_party_number(target_continent, number)
    country_list = []
    puts "========================================================================"
    puts "getting countries\' that have #{number} parties in continent: '#{target_continent}':"
    @country_lists.each do |country|
      if is_belong_to?(country, target_continent) == true
        my_html = Nokogiri::HTML(country.country_doc)
        doc = my_html.at("table tr td a[title='Notes and Definitions: Elevation extremes']")
        if doc != nil
          tmpText = doc.parent.parent.parent.next_element.at('div').text.to_s
          elev_point = (tmpText[/-?\d+/]).to_i
          country_list << (CountryElev.new(country.country_name.to_s, elev_point))
        end
      end
    end

  end

end


s = Solution.new
s.get_all_countries

#s.s1_search_natural_hazards("South America", "earthquake")
#s.s2_search_lowest_elevation_point("Europe")
#s.s3_search_hemisphere("southeastern")