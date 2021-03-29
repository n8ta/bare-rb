#!/bin/sh

ruby -v
gem install coveralls
gem install simplecov
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
python3 get-pip.py
pip3 install setuptools
ruby tests/ci.rb