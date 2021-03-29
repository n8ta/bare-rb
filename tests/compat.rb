#!/usr/bin/env ruby

require_relative '../src/lib/bare-rb'

file_path_1 = ARGV[0]
file_path_2 = ARGV[1]

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


pkey = "11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111123".b
emp = {
  name: "John Galt",
  email: "j@g.com",
  address: address,
  department: "ACCOUNTING",
  hireDate: "sometime",
  publicKey: pkey,
  metadata: {
    "ssh" => 'jafsl8dfaf2',
    "gpg" => 'jofa8f2jdlasfj8'
  }
}

file = open(file_path_1, 'w+')
file.write(Bare.encode(customer, schema[:Customer]))
file.close()

file = open(file_path_2, 'w+')
file.write(Bare.encode(emp, schema[:Employee]))
file.close()