#!/bin/sh
cd ../bare-rb
gem build bare-rb.gemspec
gem install bare-rb-0.0.0.gem
cd ../tests
ruby ./basic.rb