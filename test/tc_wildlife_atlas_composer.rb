$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require "test/unit"
require "csv"
require "hornsby_herbarium_parser"
require "wildlife_atlas_composer"

module TestWildlifeAtlasHelper
  DEFAULT_INITIAL_SPREADSHEET_FILENAME = "test/example_spreadsheets/emptyScientificLicenceDatasheet.xls"
  EMPTY_CSV_OUTPUT_FILENAME = "test/example_spreadsheets/emptyScientificLicenceDatasheet.csv"
  SINGLE_ENTRY_OUTPUT_FILENAME = "test/example_spreadsheets/SimpleWildlifeAtlasOutput.csv"

  def assert_wildlife_atlas_output_equals(expected_csv_output_filename, entry_values, observers, observation_date_string, location, initial_spreadsheet_filename, failure_message)
    entries = entry_values.map{|e| HornsbyHerbariumEntry.new(e[:genus], e[:species], e[:relative_sequential_number])}
    temporary_output_filename = "test/example_spreadsheets/temporary_output.csv"
    hornsby_herbarium_spreadsheet = HornsbyHerbariumSpreadsheet.new_using_values(entries, observers, observation_date_string,  location)
    wildlife_atlas_composer = WildlifeAtlasComposer.new_using_wildlife_atlas_filename(initial_spreadsheet_filename, hornsby_herbarium_spreadsheet)
    wildlife_atlas_composer.csv_output(temporary_output_filename)
    assert_csv_outputs_equal expected_csv_output_filename, temporary_output_filename, failure_message
    File.delete(temporary_output_filename) if File.exist?(temporary_output_filename)
  end

  def assert_csv_outputs_equal(expected_csv_output_filename, actual_csv_output_filename, failure_message)
    expected_csv_output = CSV.read(expected_csv_output_filename)
    actual_csv_output = CSV.read(actual_csv_output_filename)
    0.upto([expected_csv_output.size, actual_csv_output.size].max - 1) do |i|
      assert ! expected_csv_output[i].nil?, "#{actual_csv_output[i].inspect} not matched: expected csv output has fewer rows than actual csv output: " + failure_message
      assert ! actual_csv_output[i].nil?, "actual csv output has fewer rows than expected csv output: " + failure_message
      assert_equal expected_csv_output[i], actual_csv_output[i], failure_message
    end
  end
end

class TestWildlifeAtlasComposer < Test::Unit::TestCase
  include TestWildlifeAtlasHelper

  def test_no_data_scenario
    entry_values = []
    observers = ""
    observation_date_string = "21/7/2009"
    location = ""
    initial_spreadsheet_filename = DEFAULT_INITIAL_SPREADSHEET_FILENAME
    expected_csv_output_filename = EMPTY_CSV_OUTPUT_FILENAME
    failure_message = "Can't match up an empty output"
    assert_wildlife_atlas_output_equals expected_csv_output_filename, entry_values, observers, observation_date_string, location, initial_spreadsheet_filename, failure_message
  end

  def test_single_entry_scenario
    entry_values = [{:genus => "Homo", :species => "sapiens", :relative_sequential_number => 1}]
    observers = "Andrew Grimm"
    observation_date_string = "21/7/2009"
    location = "Las Vegas"
    initial_spreadsheet_filename = DEFAULT_INITIAL_SPREADSHEET_FILENAME
    expected_csv_output_filename = SINGLE_ENTRY_OUTPUT_FILENAME
    failure_message = "Can't handle a single entry scenario"
    assert_wildlife_atlas_output_equals expected_csv_output_filename, entry_values, observers, observation_date_string, location, initial_spreadsheet_filename, failure_message
  end

end
