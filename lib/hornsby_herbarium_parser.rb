require "rubygems"
require "roo"

class HornsbyHerbariumParser
  attr_reader :entries, :observers, :location

  def self.new_using_filename(filename)
      self.new(filename)
  end

  def initialize(filename)
    @location_parser = LocationParser.new
    @hornsby_herbarium_entry_creator = HornsbyHerbariumEntryCreator.new
    basename = File.basename(filename, ".*")
    @location = @location_parser.parse_string(basename)
    @date = parse_date_from_filename(filename)
    @general_parser = GeneralParser.new
    excel = Excel.new(filename)
    excel.default_sheet = excel.sheets.first #Assumption: only the first sheet is used in a spreadsheet
    @entries = []
    @observers = []
    0.upto(excel.last_row) do |line_number|
      row = excel.row(line_number)
      next if row.nil?

      entry = @hornsby_herbarium_entry_creator.create_if_valid(row)
      @entries << entry unless entry.nil?
      next unless entry.nil?

      location = @location_parser.parse_row(row)
      @location = location unless location.nil?

      tokens = @general_parser.parse_row(row)
      tokens.each do |token|
        if token.token_type == :date
          @date = token.token_value
        elsif token.token_type == :observer
          @observers << token.token_value
        else
          raise "Uknown type"
        end
      end
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
    taxon = TaxonParser.new.parse_row(row) #To do: don't initialize a new parser each time
    return nil if taxon.nil?
    new(taxon, relative_sequential_number)
  end

  def initialize(taxon, relative_sequential_number)
    @binomial = [taxon.genus, taxon.species].join(" ")
    @relative_sequential_number = relative_sequential_number
  end

end

class GeneralParser
  def initialize
    @observer_parser = ObserverParser.new
    @date_parser = DateParser.new
  end

  def parse_row(row)
    results = []
    row.each do |cell|
      results += parse_cell(cell)
    end
    results
  end

  def parse_cell(cell)
    results = []
    return results if cell.nil? #To satisfy runcoderun
    cell.split(/, ?/).each do |string|
      if @observer_parser.has_match_for?(string)
        results << Token.new(:observer, string)
      elsif @date_parser.parse_string(string)
        results << Token.new(:date, @date_parser.parse_string(string))
      end
    end
    results
  end

end

class Token
  attr_reader :token_type, :token_value

  def initialize(token_type, token_value)
    @token_type, @token_value = token_type, token_value
  end
end

class TaxonParser
  def initialize
    @known_taxa = parse_known_taxa_list
  end

  def parse_known_taxa_list
    result = []
    larger_group, family, genus, species = nil, nil, nil, nil
    text = File.read("config/taxa.txt")
    text.split("\n").each do |line|
      strings = line.split("\t")
      if strings.size == 1
        larger_group = *strings
      elsif strings.size == 3
        family, genus, species = *strings
        result << Taxon.new(larger_group, family, genus, species)
      elsif strings.empty?
        next
      else
        raise "Wrong number of lines in #{line}"
      end
    end
    result
  end

  def parse_row(row)
    return nil unless (row[1] and row[2])
    genus = row[1].strip
    species = row[2].strip
    @known_taxa.find{|t| t.genus == genus and t.species == species}
  end

end

class Taxon
  attr_accessor :genus, :species

  def initialize(larger_group, family, genus, species)
    @genus = genus
    @species = species
  end
end

class ObserverParser
  def initialize
    @known_observers = File.read("config/observers.txt").split("\n")
  end

  def has_match_for?(string)
    @known_observers.any?{|observer| string.include?(observer)}
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
    row.each do |cell|
      next if cell.nil?
      result = parse_string(cell)
      return result unless result.nil?
    end
    nil
  end

  def parse_string(string)
    day_s, month_s, year_s = string.split("-")
    return nil if [day_s, month_s, year_s].any?{|s| s.nil?}
    result = nil
    begin
      result = Date.parse([year_s, month_s, day_s].join("-"), true)
    rescue
    end
    result
  end

end
