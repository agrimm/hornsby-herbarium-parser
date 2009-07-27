#!/usr/bin/env ruby

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require "hornsby_herbarium_parser"
require "wildlife_atlas_composer"

unless ARGV.size == 2
  STDERR.puts "bin/hornsby_herbarium_parser.rb hornsby_herbarium_filename wildlife_atlas_output_filename"
  exit
end

hornsby_herbarium_filename = ARGV[0]
initial_wildlife_atlas_spreadsheet_filename = "test/example_spreadsheets/emptyScientificLicenceDatasheet.xls"
wildlife_atlas_output_filename = ARGV[1]

hornsby_herbarium_parser = HornsbyHerbariumParser.new_using_filename(hornsby_herbarium_filename)
validation_errors_string = hornsby_herbarium_parser.validation_errors_to_string
STDERR.puts validation_errors_string unless validation_errors_string.empty?
hornsby_herbarium_spreadsheet = hornsby_herbarium_parser.to_spreadsheet

wildlife_atlas_composer = WildlifeAtlasComposer.new_using_wildlife_atlas_filename(initial_wildlife_atlas_spreadsheet_filename, hornsby_herbarium_spreadsheet)
wildlife_atlas_composer.csv_output(wildlife_atlas_output_filename)

