require 'coveralls'
require 'simplecov'

puts "Starting code coverage"
Coveralls.wear!
SimpleCov.command_name 'Custom BARE Test Script'
puts "Calling tests.rb script"

require_relative './tests.rb'

puts "Calling bare-py compat to tests interoperability bare-rb"

compat = File.join(__dir__, "compat")
system("#{compat} #{__dir__}") || exit(-1)

