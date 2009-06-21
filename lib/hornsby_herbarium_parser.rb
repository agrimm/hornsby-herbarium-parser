require "roo"

class HornsbyHerbariumParser
  attr_reader :entries, :observers

  def self.new_using_filename(filename)
      self.new(filename)
  end

  def initialize(filename)
    @observers_list = ObserverList.new #A list of known observers, as opposed to those in this spreadsheet
    @date = parse_date_from_filename(filename)
    excel = Excel.new(filename)
    excel.default_sheet = excel.sheets.first #Assumption: only the first sheet is used in a spreadsheet
    @entries = []
    0.upto(excel.last_row) do |line_number|
      row = excel.row(line_number)
      next if row.nil?
      entry = HornsbyHerbariumEntry.new_if_valid(row)
      @entries << entry unless entry.nil?
      next unless entry.nil?
      if row_has_observers?(row)
        @observers = parse_observer_row(row)
      end
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

class HornsbyHerbariumEntry
  attr_reader :binomial

  def self.new_if_valid(row)
    return nil if row.nil?
    return nil unless row.length > 3
    return nil unless (row[0] and row[1] and row[2] and row[3])
    return nil unless (row[3] == "x" or row[3] == "X")
    new(row)
  end

  def initialize(row)
    #Assumption: all row members are strings
    genus = row[1].strip
    species = row[2].strip
    @binomial = [genus, species].join(" ")
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
