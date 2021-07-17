from collections import OrderedDict
from enum import Enum

import bare
from bare.bare_ast import TypeKind, BarePrimitive, StructType, OptionalType, NamedType, ArrayType, MapType, UnionType, UnionValue


class PublicKey:
	_ast = BarePrimitive(TypeKind.DataFixed, 128)

	def __init__(self, value=None):
		self.value = value

	def pack(self):
		return bare.pack(self)

	@classmethod
	def unpack(cls, data, offset=0):
		instance = cls()
		return bare.unpack(instance, data, offset=offset, primitive=True)


class Time:
	_ast = BarePrimitive(TypeKind.String)

	def __init__(self, value=None):
		self.value = value

	def pack(self):
		return bare.pack(self)

	@classmethod
	def unpack(cls, data, offset=0):
		instance = cls()
		return bare.unpack(instance, data, offset=offset, primitive=True)


class Department(Enum):
	ACCOUNTING = 0
	ADMINISTRATION = 1
	CUSTOMER_SERVICE = 2
	DEVELOPMENT = 3
	JSMITH = 99


class Customer:
	_ast = StructType(OrderedDict(
	name=BarePrimitive(TypeKind.String),
	email=BarePrimitive(TypeKind.String),
	address=NamedType("Address"),
	orders=ArrayType(StructType(OrderedDict(
	orderId=BarePrimitive(TypeKind.I64),
	quantity=BarePrimitive(TypeKind.I32),
))),
	metadata=MapType(BarePrimitive(TypeKind.String), BarePrimitive(TypeKind.Data)),
))

	def __init__(self):
		self.name = None
		self.email = None
		self.address = None
		self.orders = None
		self.metadata = None

	def pack(self):
		return bare.pack(self)

	@classmethod
	def unpack(cls, data, offset=0):
		instance = cls()
		bare.unpack(instance, data, offset=offset)
		return instance


class Employee:
	_ast = StructType(OrderedDict(
	name=BarePrimitive(TypeKind.String),
	email=BarePrimitive(TypeKind.String),
	address=NamedType("Address"),
	department=NamedType("Department"),
	hireDate=NamedType("Time"),
	publicKey=OptionalType(NamedType("PublicKey")),
	metadata=MapType(BarePrimitive(TypeKind.String), BarePrimitive(TypeKind.Data)),
))

	def __init__(self):
		self.name = None
		self.email = None
		self.address = None
		self.department = None
		self.hireDate = None
		self.publicKey = None
		self.metadata = None

	def pack(self):
		return bare.pack(self)

	@classmethod
	def unpack(cls, data, offset=0):
		instance = cls()
		bare.unpack(instance, data, offset=offset)
		return instance


class Person:
	_ast = UnionType([
		UnionValue(NamedType("Customer"), 0),
		UnionValue(NamedType("Employee"), 1)
	])

	@classmethod
	def pack(cls, member):
		return bare.pack(cls, member)

	@classmethod
	def unpack(cls, data, offset=0):
		instance = cls()
		return bare.unpack(instance, data, offset=offset)


class Address:
	_ast = StructType(OrderedDict(
	address=ArrayType(BarePrimitive(TypeKind.String), 4),
	city=BarePrimitive(TypeKind.String),
	state=BarePrimitive(TypeKind.String),
	country=BarePrimitive(TypeKind.String),
))

	def __init__(self):
		self.address = None
		self.city = None
		self.state = None
		self.country = None

	def pack(self):
		return bare.pack(self)

	@classmethod
	def unpack(cls, data, offset=0):
		instance = cls()
		bare.unpack(instance, data, offset=offset)
		return instance


