Gem::Specification.new do |s|
  s.name        = 'bare-rb'
  s.version     = '0.2.3'
  s.date        = '2021-10-07'
  s.summary     = "Bare Message Encoding Implementation"
  s.description = "The first implementation of the BARE (Binary Application Record Encoding) in Ruby. Includes schema parsing and random schema generation!"
  s.authors     = ["Nate Tracy-Amoroso"]
  s.email       = 'n8@u.northwestern.edu'
  s.files       = %w[./lib/bare-rb.rb ./lib/dfs.rb ./lib/types.rb ./lib/exceptions.rb ./lib/lexer.rb ./lib/parser.rb ./lib/generative_testing/gen.rb ./lib/generative_testing/monkey_patch.rb ./lib/generative_testing/grammar_util.rb ]
  s.homepage    = 'https://github.com/n8ta/bare-rb'
  s.license     = 'MIT'
  s.required_ruby_version  = '>=2.5'
end
