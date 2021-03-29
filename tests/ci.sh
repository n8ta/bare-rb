#!/bin/sh

ruby -v
gem install coveralls
gem install simplecov
pip3 install setuptools
ruby tests/ci.rb