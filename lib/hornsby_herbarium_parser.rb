require "roo"

class HornsbyHerbariumParser
  attr_reader :entries

  def self.new_using_filename(filename)
      self.new(filename)
  end

  def initialize(filename)
    excel = Excel.new(filename)
    excel.default_sheet = excel.sheets.first #Assumption: only the first sheet is used in a spreadsheet
    @entries = []
    0.upto(excel.last_row) do |line_number|
      row = excel.row(line_number)
      entry = HornsbyHerbariumEntry.new_if_valid(row)
      @entries << entry unless entry.nil?
    end
  end

  def entry_count
    @entries.size
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
