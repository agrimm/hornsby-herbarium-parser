$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require "rubygems"
require "test/unit"
require "hornsby_herbarium_parser"

module TestHelper
  SMALLER_HORNSBY_HERBARIUM_SPREADSHEET_FILENAME = "test/example_spreadsheets/Berowra Creek 150509.xls" #Not in revision control for copyright reasons
  SIMPLE_EXAMPLE_SPREADSHEET_FILENAME = "test/example_spreadsheets/Simple example 1.xls"

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
end

class TestHornsbyHerbariumParser < Test::Unit::TestCase
  include TestHelper

  def test_count_entries
    hornsby_herbarium_spreadsheet_filename = SMALLER_HORNSBY_HERBARIUM_SPREADSHEET_FILENAME
    expected_count = 29
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
end
