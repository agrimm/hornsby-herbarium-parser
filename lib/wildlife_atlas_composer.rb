class WildlifeAtlasComposer
  def self.new_using_wildlife_atlas_filename(initial_wildlife_atlas_spreadsheet_filename, hornsby_herbarium_spreadsheet)
    new(initial_wildlife_atlas_spreadsheet_filename, hornsby_herbarium_spreadsheet)
  end

  def initialize(initial_wildlife_atlas_spreadsheet_filename, hornsby_herbarium_spreadsheet)
    @excel = Excel.new(initial_wildlife_atlas_spreadsheet_filename)
  end

  def csv_output(filename)
    @excel.to_csv(filename)
  end
end
