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
    @invalid_taxa_details = []
    @entries = []
    @observers = []
    0.upto(excel.last_row) do |line_number|
      row = excel.row(line_number)
      next if row.nil?

      location = @location_parser.parse_row(row)
      @location = location unless location.nil?

      taxon = nil

      tokens = @general_parser.parse_row(row)
      tokens.each do |token|
        if token.token_type == :date
          @date = token.token_value
        elsif token.token_type == :observer
          @observers << token.token_value
        elsif token.token_type == :manual_total
          @manual_total = token.token_value
        elsif token.token_type == :taxon
          taxon = token.token_value
        elsif token.token_type == :invalid_taxon
          token_value = token.token_value
          @invalid_taxa_details << token_value
        else
          raise "Unknown type"
        end
      end

      entry = @hornsby_herbarium_entry_creator.create(taxon) unless taxon.nil?
      @entries << entry unless entry.nil?
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
    raise PartiallyCorrectTaxonNameError, "#{@invalid_taxa_details.size} partially correct taxon names" unless @invalid_taxa_details.empty?

    raise "Total is inconsistent: recorded as #{@manual_total}, should be #{entry_count}" if @manual_total != entry_count
    HornsbyHerbariumSpreadsheet.new_using_values(@entries, @observers.first, sighting_date_string, @location)
  end

  def validation_errors_to_string
    validation_error_strings = @invalid_taxa_details.map{|invalid_taxon_details| "Partially correct taxon name #{invalid_taxon_details[:genus]} #{invalid_taxon_details[:species]}" }
    validation_error_strings.join("\n")
  end
end

class HornsbyHerbariumEntryCreator

  def initialize
    @entries_created = 0
  end

  def create(taxon)
    result = HornsbyHerbariumEntry.new(taxon, @entries_created + 1)
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

  def initialize(taxon, relative_sequential_number)
    @binomial = [taxon.genus, taxon.species].join(" ")
    @relative_sequential_number = relative_sequential_number
  end

end

class GeneralParser
  def initialize
    @observer_parser = ObserverParser.new
    @date_parser = DateParser.new
    @manual_total_parser = ManualTotalParser.new
    @taxon_parser = TaxonParser.new
  end

  def parse_row(row)
    results = []
    if result = @taxon_parser.parse_row(row)
      results << result
    end
    row.each do |cell|
      results += parse_cell(cell)
    end
    results
  end

  def parse_cell(cell)
    results = []
    return results if cell.nil? #To satisfy runcoderun
    cell.split(/, ?/).each do |string|
      if result = @observer_parser.parse_string(string)
        results << result
      elsif result = @date_parser.parse_string(string)
        results << result
      elsif result = @manual_total_parser.parse_string(string)
        results << result
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
      raise "Spaces at the start or end of taxon names with #{strings.inspect}" unless strings.all?{|string| string == string.strip} #Not unit tested
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
    token_value = @known_taxa.find{|t| t.genus == genus and t.species == species}
    if (not token_value.nil?)
      token = Token.new(:taxon, token_value)
      token
    elsif @known_taxa.any?{|t| (t.genus == genus) or (t.species == species)}
      token = Token.new(:invalid_taxon, {:genus => genus, :species => species})
      token
    else
      nil
    end
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

  def parse_string(string)
    match_found = @known_observers.find{|observer| string.include?(observer)}
    return nil unless match_found
    token = Token.new(:observer, string)
    token
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

  def parse_string(string)
    day_s, month_s, year_s = string.split("-")
    return nil if [day_s, month_s, year_s].any?{|s| s.nil?}
    token_value = nil
    begin
      token_value = Date.parse([year_s, month_s, day_s].join("-"), true)
    rescue
    end
    return nil if token_value.nil?
    token = Token.new(:date, token_value)
    token
  end

end

class ManualTotalParser

  def parse_string(string)
    regexp = /^Count *= *(\d+)$/
    match_data = regexp.match(string)
    return nil if match_data.nil?
    token_value = Integer(match_data[1])
    token = Token.new(:manual_total, token_value)
    token
  end

end

class PartiallyCorrectTaxonNameError < RuntimeError
end

