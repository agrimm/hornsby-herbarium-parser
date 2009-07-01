class WildlifeAtlasComposer
  def self.new_using_wildlife_atlas_filename(initial_wildlife_atlas_spreadsheet_filename, hornsby_herbarium_spreadsheet)
    new(initial_wildlife_atlas_spreadsheet_filename, hornsby_herbarium_spreadsheet)
  end

  def initialize(initial_wildlife_atlas_spreadsheet_filename, hornsby_herbarium_spreadsheet)
    @excel = Excel.new(initial_wildlife_atlas_spreadsheet_filename)
    @hornsby_herbarium_spreadsheet = hornsby_herbarium_spreadsheet
  end

  def csv_output(filename)
    @excel.to_csv(filename)
    File.open(filename, "a") do |file|
      @hornsby_herbarium_spreadsheet.entries.each do |entry|
        values = [entry.relative_sequential_number,nil,nil,nil, entry.binomial, @hornsby_herbarium_spreadsheet.sighting_date_string, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, @hornsby_herbarium_spreadsheet.location, nil, nil, nil, nil, nil, nil, nil, @hornsby_herbarium_spreadsheet.observers, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil].map do |cell|
          unless cell.nil?
            value = "\"#{cell}\"" #Not properly escaped
          end
          value
        end
        file.puts(values.join(","))
      end
    end
  end
end

