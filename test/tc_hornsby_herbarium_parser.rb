$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require "test/unit"
require "hornsby_herbarium_parser"

module TestHelper
  LARGER_HORNSBY_HERBARIUM_SPREADSHEET_FILENAME = "test/example_spreadsheets/Berowra 15052009Species List.xls" #TODO: remove from turned off test #Not in revision control for copyright reasons
  SIMPLE_EXAMPLE_SPREADSHEET_FILENAME = "test/example_spreadsheets/Las Vegas.xls"
  INCONSISTENT_TOTAL_SPREADSHEET_FILENAME = "test/example_spreadsheets/Reno.xls"
  PARTIALLY_CORRECT_TAXON_NAME_SPREADSHEET_FILENAME = "test/example_spreadsheets/Carson city.xls"

  def assert_parser_entries_equals(expected_count, hornsby_herbarium_spreadsheet_filename, failure_message)
    hornsby_herbarium_parser = HornsbyHerbariumParser.new_using_filename(hornsby_herbarium_spreadsheet_filename)
    assert_equal expected_count, hornsby_herbarium_parser.entry_count, failure_message
  end

  def assert_first_entry_binomial_equals(expected_binomial_string, hornsby_herbarium_spreadsheet_filename, failure_message)
    hornsby_herbarium_parser = HornsbyHerbariumParser.new_using_filename(hornsby_herbarium_spreadsheet_filename)
    hornsby_herbarium_entry = hornsby_herbarium_parser.entries[0]
    actual_binomial_string = hornsby_herbarium_entry.binomial.to_s
    assert_equal expected_binomial_string, actual_binomial_string, failure_message
  end

  def assert_observers_equals(expected_observers_string, hornsby_herbarium_spreadsheet_filename, failure_message)
    hornsby_herbarium_parser = HornsbyHerbariumParser.new_using_filename(hornsby_herbarium_spreadsheet_filename)
    actual_observers_string = hornsby_herbarium_parser.observers.to_s
    assert_equal expected_observers_string, actual_observers_string, failure_message
  end

  def assert_location_equals(expected_location_string, hornsby_herbarium_spreadsheet_filename, failure_message)
    hornsby_herbarium_parser = HornsbyHerbariumParser.new_using_filename(hornsby_herbarium_spreadsheet_filename)
    actual_location_string = hornsby_herbarium_parser.location.to_s
    assert_equal expected_location_string, actual_location_string, failure_message
  end

  def assert_sighting_date_string_equals(expected_date_string, hornsby_herbarium_spreadsheet_filename, failure_message)
    hornsby_herbarium_parser = HornsbyHerbariumParser.new_using_filename(hornsby_herbarium_spreadsheet_filename)
    actual_date_string = hornsby_herbarium_parser.sighting_date_string
    assert_equal expected_date_string, actual_date_string, failure_message
  end

  def assert_relative_sequential_numbers_equals(expected_relative_sequential_numbers, hornsby_herbarium_spreadsheet_filename, failure_message)
    hornsby_herbarium_parser = HornsbyHerbariumParser.new_using_filename(hornsby_herbarium_spreadsheet_filename)
    hornsby_herbarium_entries = hornsby_herbarium_parser.entries
    actual_relative_sequential_numbers = hornsby_herbarium_entries.map {|entry| entry.relative_sequential_number}
    assert_equal expected_relative_sequential_numbers, actual_relative_sequential_numbers, failure_message
  end

  def assert_hornsby_herbarium_parser_raises(hornsby_herbarium_spreadsheet_filename, expected_exception_type, expected_exception_message, failure_message)
    begin
      hornsby_herbarium_parser = HornsbyHerbariumParser.new_using_filename(hornsby_herbarium_spreadsheet_filename)
      hornsby_herbarium_parser.to_spreadsheet
    rescue expected_exception_type => actual_exception
      assert_equal expected_exception_message, actual_exception.message, "Wrong error message " + failure_message
    rescue StandardError => actual_exception
      flunk "Wrong type of exception: #{actual_exception.inspect} " + failure_message
    else
      flunk "No exception at all " + failure_message
    end
  end
end

class TestHornsbyHerbariumParser < Test::Unit::TestCase
  include TestHelper

  def test_count_entries
    hornsby_herbarium_spreadsheet_filename = SIMPLE_EXAMPLE_SPREADSHEET_FILENAME
    expected_count = 1
    failure_message = "Can't count the number of entries"
    assert_parser_entries_equals expected_count, hornsby_herbarium_spreadsheet_filename, failure_message
  end

  def test_species_name_parsing
    hornsby_herbarium_spreadsheet_filename = SIMPLE_EXAMPLE_SPREADSHEET_FILENAME
    expected_binomial_string = "Homo sapiens"
    failure_message = "Can't extract a binomial"
    assert_first_entry_binomial_equals expected_binomial_string, hornsby_herbarium_spreadsheet_filename, failure_message
  end

  def test_observer_parsing
    hornsby_herbarium_spreadsheet_filename = SIMPLE_EXAMPLE_SPREADSHEET_FILENAME
    expected_observers_string = "Andrew Grimm"
    failure_message = "Can't parse observers"
    assert_observers_equals expected_observers_string, hornsby_herbarium_spreadsheet_filename, failure_message
  end

  def test_location_parsing
    hornsby_herbarium_spreadsheet_filename = SIMPLE_EXAMPLE_SPREADSHEET_FILENAME
    expected_location_string = "Las Vegas"
    failure_message = "Can't parse location"
    assert_location_equals expected_location_string, hornsby_herbarium_spreadsheet_filename, failure_message
  end

  def test_date_parsing
    hornsby_herbarium_spreadsheet_filename = SIMPLE_EXAMPLE_SPREADSHEET_FILENAME
    expected_date_string = "21/6/2009"
    failure_message = "Can't parse dates"
    assert_sighting_date_string_equals expected_date_string, hornsby_herbarium_spreadsheet_filename, failure_message
  end

  def dont_test_four_year_date_parsing
    hornsby_herbarium_spreadsheet_filename = LARGER_HORNSBY_HERBARIUM_SPREADSHEET_FILENAME
    expected_date_string = "15/5/2009"
    failure_message = "Can't parse dates"
    assert_sighting_date_string_equals expected_date_string, hornsby_herbarium_spreadsheet_filename, failure_message
  end

  def test_relative_sequential_number
    hornsby_herbarium_spreadsheet_filename = SIMPLE_EXAMPLE_SPREADSHEET_FILENAME
    expected_relative_sequential_numbers = [1]
    failure_message = "Can't do relative sequential numbers"
    assert_relative_sequential_numbers_equals expected_relative_sequential_numbers, hornsby_herbarium_spreadsheet_filename, failure_message
  end

  def test_detect_inconsistent_count
    hornsby_herbarium_spreadsheet_filename = INCONSISTENT_TOTAL_SPREADSHEET_FILENAME
    expected_exception_type = RuntimeError
    expected_exception_message = "Total is inconsistent: recorded as 2, should be 1"
    failure_message = "Fails to detect inconsistent total"
    assert_hornsby_herbarium_parser_raises hornsby_herbarium_spreadsheet_filename, expected_exception_type, expected_exception_message, failure_message
  end

  def test_detect_partially_correct_taxon_names
    hornsby_herbarium_spreadsheet_filename = PARTIALLY_CORRECT_TAXON_NAME_SPREADSHEET_FILENAME
    expected_exception_type = PartiallyCorrectTaxonNameError
    expected_exception_message = "1 partially correct taxon names"
    failure_message = "Fails to detect partially correct taxon names"
    assert_hornsby_herbarium_parser_raises hornsby_herbarium_spreadsheet_filename, expected_exception_type, expected_exception_message, failure_message
  end


end
