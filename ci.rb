#!/usr/bin/env ruby
require 'coveralls'
require 'simplecov'

puts "Starting code coverage"
Coveralls.wear!
SimpleCov.command_name 'Custom BARE Test Script'
puts "Calling tests.rb script"

require_relative 'tests/tests.rb'

puts "Calling bare-py to test interoperability"
compat_tests_dir = File.join(__dir__, "compat_tests")
compat = File.join(compat_tests_dir, "combat")

system("#{compat} #{__dir__}", chdir: compat_tests_dir) || exit(-1)

