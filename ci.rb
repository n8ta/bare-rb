#!/usr/bin/env ruby
require 'coveralls'
require 'simplecov'

puts "Starting code coverage"
Coveralls.wear!
SimpleCov.command_name 'Custom BARE Test Script'
puts "Calling tests.rb script"

require_relative 'tests/tests.rb'

puts "Calling bare-py to test interoperability"

compat = File.join(__dir__,  "tests", "compat")
system("#{compat} #{__dir__}", chdir: 'tests') || exit(-1)

