Gem::Specification.new do |s|
  s.name        = 'bare-rb'
  s.version     = '0.1.4'
  s.date        = '2020-10-13'
  s.summary     = "Bare Message Encoding Implementation"
  s.description = "The first implementation of the BARE (Binary Application Record Encoding) in Ruby. Includes schema parsing!"
  s.authors     = ["Nate Tracy-Amoroso"]
  s.email       = 'n8@u.northwestern.edu'
  s.files       = ["./lib/bare-rb.rb", "./lib/types.rb", "./lib/exceptions.rb", "./lib/lexer.rb", "./lib/parser.rb"]
  s.homepage    = 'https://github.com/n8ta/bare-rb'
  s.license     = 'MIT'
end
