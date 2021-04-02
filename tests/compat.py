import bare
import sys
from bare.bare_ast import TypeKind, BarePrimitive, StructType, OptionalType, NamedType, ArrayType, MapType, UnionType, UnionValue

file_path1 = sys.argv[1]
file_path2 = sys.argv[2]

from demo import Customer, Address, Employee, Department, Time, PublicKey

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

dept = Department(Department.ACCOUNTING)
time = Time("sometime")
pkey = PublicKey(value=b'11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111123')

emp = Employee()
emp.name = "John Galt"
emp.email = "j@g.com"
emp.address = address
emp.department = dept
emp.hireDate = time
emp.publicKey = pkey
emp.metadata = {
    'ssh': b'jafsl8dfaf2',
    'gpg': b'jofa8f2jdlasfj8'
}



with open(file_path1, 'wb') as handle:
    handle.write(customer.pack())

with open(file_path2, 'wb') as handle:
    handle.write(emp.pack())