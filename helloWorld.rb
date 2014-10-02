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

class CountryComparable
  include Comparable
  attr_accessor :country_name
  attr_accessor :country_value

  def <=>(that)
    country_value <=> that.country_value
  end

  def initialize(country_name, country_value)
    @country_name = country_name
    @country_value = country_value
  end

  def to_s()
    return (country_name.to_s + "  " + country_value.to_s)
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
    @country_lists = Hash.new []
    @CIA_URL =  %Q|https://www.cia.gov/library/publications/the-world-factbook/print/textversion.html|
  end

  # get all countries in sorted order
  def get_all_countries
    puts "collecting countries infomation.."
    doc = Nokogiri::HTML(open(@CIA_URL))

    doc.css("ul#GetAppendix_TextVersion li a").each do |item|
      country_name = item.text
      next if country_name == "World"
      country_url =  @CIA_URL
      new_url = (country_url.split('/')[0..-2]).join('/')
      country_url = new_url << '/' << item['href']
      puts "#{country_name}"
      f = open(country_url)
      doc = f.read()
      f.close()
      country = CountryURL.new(country_name, country_url, doc)
      continent = get_continent(doc)
      if continent != nil
        continent.downcase!
        @country_lists[continent] += [country]
      end
    end
    puts "========================================================================"
    puts "========================================================================"
    puts "==============================start parsing============================="
    puts "========================================================================"
    puts "========================================================================"
  end

  # print all countries
  def print_all_countries
    @country_lists.each do |country|
      puts puts "#{country.country_name}\t#{}"
    end
  end

  # get a country's continent
  def get_continent(country_doc)
    my_html = Nokogiri::HTML(country_doc)
    doc = my_html.at("table tr td div.region1 a")
    region = nil
    if doc != nil then
      region = doc.text.to_s
      if str_include?(region, 'Asia')
        region = 'Asia'
      elsif str_include?(region, 'middle east')
        region = 'Asia'
      end
    end
    return region
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

  def compute_consumption(num, unity)
    u = 1
    unity.downcase!
    if unity == "trillion"
      u = 1e12
    elsif unity == "billion"
      u = 1e9
    elsif unity == "million"
      u = 1e6
    end
    result = num * u
    return result
  end
  #check if is belong to a continent
  #is deprecated
  def is_belong_to?(country, target_continent)
    my_html = Nokogiri::HTML(country.country_doc)
    doc = my_html.at("table tr td div.region1 a")
    belong = false

    if doc != nil then
      region = doc.text
      if str_include?(region, target_continent)
        belong = true
      end
    end
    return belong
  end

  #search for natural hazards
  def s1_search_natural_hazards(target_continent, target_word)
    continent_country_lists = []
    puts "========================================================================"
    puts "getting countries in continent: '#{target_continent}'that are prone to natural hazard'#{target_word}':"
    target_continent.downcase!
    if @country_lists.has_key?(target_continent)
      @country_lists[target_continent].each do |country|
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
    target_continent.downcase!
    if @country_lists.has_key?(target_continent)
      @country_lists[target_continent].each do |country|
 #     puts country.country_name
        my_html = Nokogiri::HTML(country.country_doc)
        doc = my_html.at("table tr td a[title='Notes and Definitions: Elevation extremes']")
        if doc != nil
          tmpText = doc.parent.parent.parent.next_element.at('div').text.to_s
          elev_point = (tmpText[/-?\d+/]).to_i
          country_list << (CountryComparable.new(country.country_name.to_s, elev_point))
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
    result_list = country_list.select{|x| x.country_value == min_elevation.country_value}

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
    @country_lists.each do |key, array|
      array.each do |country|
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
       #       puts country.country_name
            end
          end
        end
      end
    end
    country_list.sort!
    country_list.each{ |x| puts x}
    country_list
  end

  def s4_search_party_number(target_continent, number)
    #/\[[A-Za-z0-9_]*\s*[A-Za-z0-9_]*\]/m
    #/\[[^\[]*\]/m
    #/\[[^\[\]]*\]/m
    country_list = []
    puts "========================================================================"
    puts "getting countries\' that have more than #{number} parties in continent: '#{target_continent}':"
    target_continent.downcase!
    if @country_lists.has_key?(target_continent)
      @country_lists[target_continent].each { |country|
     #   puts country.country_name
        my_html = Nokogiri::HTML(country.country_doc)
        doc = my_html.at("table tr td a[title='Notes and Definitions: Political parties and leaders']")
        if doc != nil
          tmpText = doc.parent.parent.parent.next_element.at('td')
          text1 = ""
          tmpText.css('div').each do |t|
            text1 += t.text
            text1 += " "
          end
          #  puts text1.scan(/\[[^\[\]]*\]/m).to_s
          num = text1.scan(/\[[^\[\]]*\]/m).size
          if num > number
            puts country.country_name
            country_list << country.country_name
          end
        end
      }
      country_list
    end

  end

  #per captia
  def s5_search_top_electricity_consumption(topNumber)
    puts "========================================================================"
    puts "getting top #{topNumber} countries with highest electricity consumption per capita:"
    country_lists = []
    @country_lists.each do |key, array|
      array.each do |country|
        my_html = Nokogiri::HTML(country.country_doc)
        doc = my_html.at("table tr td a[title='Notes and Definitions: Electricity - consumption']")
        puts country.country_name
        if doc != nil
          tmpText = doc.parent.parent.parent.next_element.at('div').text.to_s.split(' ')
          print tmpText[0], tmpText[1]
          num = tmpText[0].gsub(',','').to_f
          num = compute_consumption(num, tmpText[1].to_s)
          puts num
        end

        doc = my_html.at("table tr td a[title='Notes and Definitions: Population']")
        population = 0
        if doc != nil
          tmpText = doc.parent.parent.parent.next_element.at('div').text.to_s.split(' ')
          population = tmpText[0].gsub(',','').to_f
          puts population
        end
        result = 0
        if population != 0
          result = num / population
        end
        country_lists << (CountryComparable.new(country.country_name, result))
      end
    end
    tmp = "finished"
  end
end


s = Solution.new
s.get_all_countries

#puts country_lists.keys
s.s1_search_natural_hazards("South America", "earthquake")
s.s2_search_lowest_elevation_point("Europe")
s.s3_search_hemisphere("southerneast")
s.s4_search_party_number("Asia", 10)
#s.s5_search_top_electricity_consumption(5)
a = 1
puts a