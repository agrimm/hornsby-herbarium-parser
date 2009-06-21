$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require "test/unit"
require "csv"
require "hornsby_herbarium_parser"
require "wildlife_atlas_composer"

module TestWildlifeAtlasHelper
  DEFAULT_INITIAL_SPREADSHEET_FILENAME = "test/example_spreadsheets/emptyScientificLicenceDatasheet.xls"
  EMPTY_CSV_OUTPUT_FILENAME = "test/example_spreadsheets/emptyScientificLicenceDatasheet.csv"

  def assert_wildlife_atlas_output_equals(expected_csv_output_filename, entries, observers, location, initial_spreadsheet_filename, failure_message)
    temporary_output_filename = "test/example_spreadsheets/temporary_output.csv"
    hornsby_herbarium_spreadsheet = HornsbyHerbariumSpreadsheet.new_using_values(entries, observers, location)
    wildlife_atlas_composer = WildlifeAtlasComposer.new_using_wildlife_atlas_filename(initial_spreadsheet_filename, hornsby_herbarium_spreadsheet)
    wildlife_atlas_composer.csv_output(temporary_output_filename)
    assert_equal CSV.read(expected_csv_output_filename), CSV.read(temporary_output_filename)
    File.delete(temporary_output_filename) if File.exist?(temporary_output_filename)
  end

end

class TestWildlifeAtlasComposer < Test::Unit::TestCase
  include TestWildlifeAtlasHelper

  def test_no_data_scenario
    entries = []
    observers = ""
    location = ""
    initial_spreadsheet_filename = DEFAULT_INITIAL_SPREADSHEET_FILENAME
    expected_csv_output_filename = EMPTY_CSV_OUTPUT_FILENAME
    failure_message = "Can't match up an empty output"
    assert_wildlife_atlas_output_equals expected_csv_output_filename, entries, observers, location, initial_spreadsheet_filename, failure_message
  end

end
