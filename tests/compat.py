#!/usr/bin/env python3.6

import bare
import sys
from bare.bare_ast import TypeKind, BarePrimitive, StructType, OptionalType, NamedType, ArrayType, MapType, UnionType, UnionValue

file_path = sys.argv[1]

from demo import Customer, Address

address = Address()
address.address = ["Address line 1", "", "", ""]
address.city = "The big city"
address.state = "Drenthe"
address.country = "The Netherlands"

customer = Customer()
customer.name = "Martijn Braam"
customer.email = "spam@example.org"
customer.address = address
customer.orders = [
    {'orderId': 5, 'quantity': 1},
    {'orderId': 6, 'quantity': 2}
]
customer.metadata = {
    'ssh': b'jafsl8dfaf2',
    'gpg': b'jofa8f2jdlasfj8'
}

with open(file_path, 'wb') as handle:
    handle.write(customer.pack())