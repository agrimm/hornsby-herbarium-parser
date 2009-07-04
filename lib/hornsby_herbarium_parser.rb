require "rubygems"
require "roo"

class HornsbyHerbariumParser
  attr_reader :entries, :observers, :location

  def self.new_using_filename(filename)
      self.new(filename)
  end

  def initialize(filename)
    @observer_parser = ObserverParser.new
    @location_parser = LocationParser.new
    @hornsby_herbarium_entry_creator = HornsbyHerbariumEntryCreator.new
    basename = File.basename(filename, ".*")
    @location = @location_parser.parse_string(basename)
    @date = parse_date_from_filename(filename)
    @date_parser = DateParser.new
    excel = Excel.new(filename)
    excel.default_sheet = excel.sheets.first #Assumption: only the first sheet is used in a spreadsheet
    @entries = []
    0.upto(excel.last_row) do |line_number|
      row = excel.row(line_number)
      next if row.nil?

      entry = @hornsby_herbarium_entry_creator.create_if_valid(row)
      @entries << entry unless entry.nil?
      next unless entry.nil?

      observers = @observer_parser.parse_row(row)
      @observers = observers unless observers.nil?
      next unless observers.nil?

      location = @location_parser.parse_row(row)
      @location = location unless location.nil?

      date = @date_parser.parse_row(row)
      @date = date unless date.nil?
    end
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
    raise "Date is too early" if result.year < 1990 #Todo: move this where it can be used regardless of where the date was generated
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

  def to_spreadsheet
    HornsbyHerbariumSpreadsheet.new_using_values(@entries, @observers.first, sighting_date_string, @location)
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
  attr_reader :entries, :observers, :sighting_date_string, :location

  def self.new_using_values(entries, observers, sighting_date_string, location)
    new(entries, observers, sighting_date_string, location)
  end

  def initialize(entries, observers, sighting_date_string, location)
    @entries, @observers, @sighting_date_string, @location = entries, observers, sighting_date_string, location
    raise "Unknown location" unless @location
  end

end

class HornsbyHerbariumEntry
  attr_reader :binomial, :relative_sequential_number

  def self.new_if_valid(row, relative_sequential_number)
    return nil if row.nil?
    return nil unless row.length > 2
    return nil unless (row[1] and row[2])
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

class ObserverParser
  def initialize
    @known_observers = File.read("config/observers.txt").split("\n")
  end

  def has_match_for?(string)
    @known_observers.any?{|observer| string.include?(observer)}
  end

  def parse_row(row)
    result = []
    row.each do |cell|
      next if cell.nil?
      result << cell if has_match_for?(cell)
    end
    return nil if result.empty?
    result
  end

end

class LocationParser
  def initialize
    @known_locations = File.read("config/locations.txt").split("\n")
  end

  def parse_row(row)
    return nil if row[0].nil?
    parse_string(row[0])
  end

  def parse_string(potential_location_string)
    if @known_locations.any?{|known_location| potential_location_string == known_location}
      potential_location_string
    else
      nil
    end
  end
end

class DateParser

  def parse_row(row)
    return nil if row[0].nil?
    day_s, month_s, year_s = row[0].split("-")
    return nil if [day_s, month_s, year_s].any?{|s| s.nil?}
    result = nil
    begin
      result = Date.parse([year_s, month_s, day_s].join("-"), true)
    rescue
    end
    result
  end

end
