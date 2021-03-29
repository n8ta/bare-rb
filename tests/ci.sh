#!/bin/sh

ruby -v
gem install coveralls
gem install simplecov
python3 -m pip install setuptools
ruby tests/ci.rb