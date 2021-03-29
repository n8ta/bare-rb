#!/bin/sh

ruby -v
gem install coveralls
gem install simplecov
apt-get install python3-pip
pip3 install setuptools
ruby tests/ci.rb