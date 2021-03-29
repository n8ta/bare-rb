#!/bin/sh

gem install coveralls
gem install simplecov
pip3 install setuptools
ruby tests/ci.rb