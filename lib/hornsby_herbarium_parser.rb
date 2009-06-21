require "rubygems"
require "roo"

class HornsbyHerbariumParser
  attr_reader :entries, :observers, :location

  def self.new_using_filename(filename)
      self.new(filename)
  end

  def initialize(filename)
    @observers_list = ObserverList.new #A list of known observers, as opposed to those in this spreadsheet
    @location_parser = LocationParser.new #Trying a more encapsulated approach than ObserverList
    @hornsby_herbarium_entry_creator = HornsbyHerbariumEntryCreator.new
    @date = parse_date_from_filename(filename)
    excel = Excel.new(filename)
    excel.default_sheet = excel.sheets.first #Assumption: only the first sheet is used in a spreadsheet
    @entries = []
    0.upto(excel.last_row) do |line_number|
      row = excel.row(line_number)
      next if row.nil?
      entry = @hornsby_herbarium_entry_creator.create_if_valid(row)
      @entries << entry unless entry.nil?
      next unless entry.nil?
      if row_has_observers?(row)
        @observers = parse_observer_row(row)
      end
      location = @location_parser.parse_row(row)
      @location = location unless location.nil?
    end
  end

  #Parsing observers is very basic right now, because I'm not sure
  #how observers are listed
  def row_has_observers?(row)
    string_containing_rows = row.find_all{|cell| not cell.nil?}
    joined_string = string_containing_rows.join(" ")
    return @observers_list.has_match_for?(joined_string)
  end

  def parse_observer_row(row)
    row.join(" ")
  end

  def entry_count
    @entries.size
  end

  def parse_date_from_filename(filename)
    if filename =~ /(\d{8})/
      date_string = $1
      day = date_string[0..1].to_i #This uses Australian-style date formatting
      month = date_string[2..3].to_i
      year = date_string[4..7].to_i
      result = Date.parse("#{year}-#{month}-#{day}", false)
    elsif filename =~ /(\d{6})/
      date_string = $1
      day = date_string[0..1].to_i
      month = date_string[2..3].to_i
      year = date_string[4..5].to_i
      result = Date.parse("#{year}-#{month}-#{day}", true)
    else
      result = nil
    end
    return result if result.nil?
    raise "Date is too early" if result.year < 1990
    raise "Date is in the future" if result > Date.today
    result
  end

  def sighting_date_string
    if @date.nil?
      ""
    else
      "#{@date.day}/#{@date.month}/#{@date.year}"
    end
  end
end

class HornsbyHerbariumEntryCreator

  def initialize
    @entries_created = 0
  end

  def create_if_valid(row)
    result = HornsbyHerbariumEntry.new_if_valid(row, @entries_created + 1)
    @entries_created += 1 unless result.nil?
    result
  end

end

class HornsbyHerbariumSpreadsheet
  attr_reader :entries, :observers, :observation_date_string, :location

  def self.new_using_values(entries, observers, observation_date_string, location)
    new(entries, observers, observation_date_string, location)
  end

  def initialize(entries, observers, observation_date_string, location)
    @entries, @observers, @observation_date_string, @location = entries, observers, observation_date_string, location
  end

end

class HornsbyHerbariumEntry
  attr_reader :binomial, :relative_sequential_number

  def self.new_if_valid(row, relative_sequential_number)
    return nil if row.nil?
    return nil unless row.length > 3
    return nil unless (row[0] and row[1] and row[2] and row[3])
    return nil unless (row[3] == "x" or row[3] == "X")
    #Assumption: all row members are strings
    genus = row[1].strip
    species = row[2].strip
    new(genus, species, relative_sequential_number)
  end

  def initialize(genus, species, relative_sequential_number)
    @binomial = [genus, species].join(" ")
    @relative_sequential_number = relative_sequential_number
  end

end

class ObserverList
  def initialize
    @observers = File.read("config/observers.txt").split("\n")
  end

  def has_match_for?(string)
    @observers.any?{|observer| string.include?(observer)}
  end

end

class LocationParser
  def initialize
    @known_locations = File.read("config/locations.txt").split("\n")
  end

  def parse_row(row)
    return nil if row[0].nil?
    potential_location_string = row[0]
    if @known_locations.any?{|known_location| potential_location_string == known_location}
      potential_location_string
    else
      nil
    end
  end
end
