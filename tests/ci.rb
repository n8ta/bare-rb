require 'coveralls'
require 'simplecov'

Coveralls.wear!
SimpleCov.command_name 'Custom BARE Test Script'

require_relative './tests.rb'
