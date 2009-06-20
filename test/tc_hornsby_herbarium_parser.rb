$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require "rubygems"
require "test/unit"
require "hornsby_herbarium_parser"

module TestHelper
  SMALLER_HORNSBY_HERBARIUM_SPREADSHEET_FILENAME = "test/example_spreadsheets/Berowra Creek 150509.xls" #Not in revision control for copyright reasons

  def assert_parser_entries_equals(expected_count, hornsby_herbarium_spreadsheet_filename, failure_message)
    hornsby_herbarium_parser = HornsbyHerbariumParser.new_using_filename(hornsby_herbarium_spreadsheet_filename)
    assert_equal expected_count, hornsby_herbarium_parser.entry_count, failure_message
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
end
