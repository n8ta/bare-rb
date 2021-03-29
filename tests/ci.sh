#!/bin/sh

ruby -v
gem install coveralls
gem install simplecov
echo "Installing setuptools"
python3 -m pip install setuptools
echo "Done installing setuptools"
ruby tests/ci.rb