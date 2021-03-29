#!/usr/bin/env ruby

require_relative '../src/lib/bare-rb'

file_path = ARGV[0]

schema = Bare.parse_schema("./demo.schema")

address = {
  address: ["Address line 1", "", "", ""],
  city: "The big city",
  state: "Drenthe",
  country: "The Netherlands" }

customer = {
  name: "Martijn Braam",
  email: "spam@example.org",
  address: address,
  orders: [
    { 'orderId': 5, 'quantity': 1 },
    { 'orderId': 6, 'quantity': 2 }
  ],
  metadata: {
    "ssh" => "jafsl8dfaf2",
    "gpg" => "jofa8f2jdlasfj8",
  }
}

file = open(file_path, 'w+')
file.write(Bare.encode(customer, schema[:Customer]))
file.close()