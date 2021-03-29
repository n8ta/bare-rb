# bare-rb
![Build Status on Travis CI](https://api.travis-ci.com/n8ta/bare-rb.svg?branch=master)
[![Coverage Status on Coveralls](https://coveralls.io/repos/github/n8ta/bare-rb/badge.svg?branch=master)](https://coveralls.io/github/n8ta/bare-rb?branch=master)

![Ruby 2.5](https://img.shields.io/badge/Ruby-2.5-brightgreen)
![Ruby 2.6](https://img.shields.io/badge/Ruby-2.6-brightgreen)
![Ruby 2.7](https://img.shields.io/badge/Ruby-2.7-brightgreen)

Implementation of the [Bare message protocol](https://baremessages.org/) in Ruby

BARE is a simple efficient binary encoding. It's primary advantage over json
 is it's structured nature and smaller messages sizes. Messages are smaller because they do not describe themselves (no key names). 
 This means the same message schema must be present on the sender and receiver.  

This implementation is complete but hasn't be rigorously tested for compatibility with another implementation. Please file an issue here on github if you find a bug.
Feel free to submit a PR with your own fixes or improvements, just be sure to run the tests.

# Installation
```shell script
# Install locally
gem install bare-rb
```
```ruby
# Add to Gemfile
gem 'bare-rb'
```

## Example Without Schema File
And then just require the gem when you want to use it:
```ruby
# Define your schema: here a variable length array of unsigned 1 byte integers
require 'bare-rb'
schema = Bare.Array(Bare.U8) 
output = Bare.encode([1,2,3,4], schema)
puts output.inspect
=> "\x04\x01\x02\x03\x04"
# You must know what schema was used to encode data to decode it
Bare.decode(output, schema) 
=> [1, 2, 3, 4]
```

## More Complex Example Without Schema File
If you need to create referential types you can use symbols as placeholders. 
You'll also need to wrap your object in a call to Bare.Schema.
```ruby
require 'bare-rb'
# Schema accepts a hash of symbols starting with a capital letter to bare types.
# You'll need to specify which type in a schema you are referring to when encoding/decoding.
# Type 1 is an int, Type 2 is a reference to Type 1 plus a string.
schema = Bare.Schema({
  Type2: Bare.Struct({ 
    t1: :Type1,
    name: Bare.String
  }),
  Type1: Bare.Int 
})

# Notice below we specify schema[:Type2] as it now ambiguous to just supply schema
output = Bare.encode({t1: 5, name: "Some Name"}, schema[:Type2])
```

## Example With Schema File
```
# ./test3.schema
type Customer {
  name: string
  email: string
  orders: []{
    orderId: i64
    quantity: i32
  }
  metadata: map[string]data
}
```

```ruby
require 'bare-rb'
schema = Bare.parse_schema('./test3.schema')
# Schema returns a hash so you must select which type in the hash you want 
# {:Customer => Bare.Struct(...) }

msg = {name: "和製漢字",
       email: "n8 AYT u.northwestern.edu",
       orders: [{orderId: 5, quantity: 11},
                {orderId: 6, quantity: 2},
                {orderId: 123, quantity: -5}],
       metadata: {"Something" => "\xFF\xFF\x00\x01".b, "Else" => "\xFF\xFF\x00\x00\xAB\xCC\xAB".b}
}

encoded = Bare.encode(msg, schema[:Customer])
decoded = Bare.decode(encoded, schema[:Customer])

msg == decoded
# True
```

# Compatiblity
- Ruby 2.7
- Ruby 2.6
- Ruby 2.5

# Type Examples & Documentation
1. [uint](#uint)
2. [int](#int)
3. [u8 u16 u32 36](#unsigned-ints)
4. [i8 i16 i32 i64](#signed-ints)
5. [f32 f64](#floats)
6. [bool](#bool)
7. [enum](#enum)
8. [string](#string)
9. [data](#fixed-length-data)
10. [data](#data)
11. [void](#void)
12. [optional<type>](#optional)
13. [array<type>](fixed-length-array)
14. [array<type>](#array)
15. [map type -> type](#map)
16. [union (type1 | type2 | type3)](#union)
17. [struct](#struct)

### uint
Variable length unsigned integer
```ruby
schema = Bare.Uint
output = Bare.encode(5, schema)
puts output.inspect
=> "\x05".b
Bare.decode(output, schema)
=> 5
```
### int
Variable length signed integer
```ruby
schema = Bare.Int
output = Bare.encode(-2, schema)
puts output.inspect
=> "\x03".b
Bare.decode(output, schema)
=> -2
```

### unsigned ints
U8, U16, U32, U64
```ruby
schema = Bare.U16
output = Bare.encode(9, schema)
puts output.size 
=> 2
Bare.decode(output, schema)
=> 9
```

### signed ints
I8, I16, I32, I64
```ruby
schema = Bare.I16
output = Bare.encode(-9, schema)
puts output.size 
=> 2
Bare.decode(output, schema)
=> -9
```
### floats
F32, F64
```ruby
schema = Bare.F32
output = Bare.encode(-13.3, schema)
puts output.size 
=> 4
Bare.decode(output, schema)
=> -13.3
```

### bool
Ruby true or false
```ruby
schema = Bare.Bool
output = Bare.encode(false, schema)
puts output.inspect
=> "\x00\x00"
Bare.decode(output, schema)
=> false
```

### enum
Accepts a hash from ints to ruby objects. Ints must be positive. 
```ruby
schema = Bare.Enum({1 => "abc", 5 => :cow, 16382 => 123})
output = Bare.encode(:cow, schema)
puts output.inspect
=> "\x05"
Bare.decode(output, schema)
=> :cow
```

### string
Accepts a string and if it isn't UTF-8 attempts to convert it using rubies `msg.encode("UTF-8").b`. 
This may fail for some encodings. If it does you may want to use the data type instead.
```ruby
schema = Bare.String
output = Bare.encode("You need to construct additional pylons", schema)
puts output.bytes.inspect 
=> [39, 89, 111, 117, 32, 110, 101, 101, 100, 32, 116, 111, 32, 99, 111, 110, 115, 116, 114, 117, 99, 116, 32, 97, 100, 100, 105, 116, 105, 111, 110, 97, 108, 32, 112, 121, 108, 111, 110, 115]
Bare.decode(output, schema)
=> "You need to construct additional pylons"
```

### fixed-length-data
Binary data of a known length
```ruby
schema = Bare.DataFixedLen(5) # length is 5 
output = Bare.encode("\x00\x01\x02\x03\x04".b, schema)
puts output.inspect 
=> "\x00\x01\x02\x03\x04"
Bare.decode(output, schema)
=> "\x00\x01\x02\x03\x04"
```

### data
Binary data of a variable length
```ruby
schema = Bare.Data 
output = Bare.encode("\x00\x01\x02\x03\x04".b, schema)
puts output.inspect 
=> "\x05\x00\x01\x02\x03\x04"
Bare.decode(output, schema)
=> "\x00\x01\x02\x03\x04"
```

### void
"A type with zero length. It is useful to create user-defined types which alias void to create discrete options in a tagged union which do not have any underlying storage." 
[-source](https://baremessages.org/)
```ruby
schema = Bare.Void 
output = Bare.encode(nil, schema)
puts output.inspect 
=> ""
Bare.decode(output, schema)
=> nil

schema2 = Bare.Union({0 => Bare.Uint, 1 => Bare.Void})
output = Bare.encode({type: Bare.Void, value: nil}, schema2)
puts output.inspect
=> "\x01" # Notice only the type encoding from union, no other data to represent void
decoded = Bare.decode(output, schema2)
puts decode.inspect
=> { value: nil, type: #<BareTypes::Void:0x00007ffe9a20b868> }
decoded[:type] == Bare.Void
=> true
```

### optional
A type which may or may not be present. Pass nil to indicate the value if not present on the normal type of the value if it is.
```ruby
schema = Bare.Optional(Bare.U8)
output = Bare.encode(5, schema)
puts output.inspect
=> "\xFF\x05"
Bare.decode(output, schema)
=> 5
```
```ruby
schema = Bare.Optional(Bare.U8)
output = Bare.encode(nil, schema)
puts output.inspect
=> "\x00"
Bare.decode(output, schema)
=> nil
```

### fixed length array
Array of a set type of a set length
```ruby
schema = Bare.ArrayFixedLen(Bare.U8, 3)
output = Bare.encode([5,3,1], schema)
puts output.inspect
=> "\x05\x03\x01"
Bare.decode(output, schema)
=> [5,3,1]
```

### map
Mapping from one type to another. 
First arg is from type, second is to type. When decoded it returns a hash.

Ruby hashes have order, if a key is specified more than one in the input or in encoded data the final value is used.
```ruby
schema = Bare.Map(Bare.Uint, Bare.String)
output = Bare.encode({3 => "Ut-oh"}, schema)
puts output.inspect
=> "\x01\x03\x05Ut-oh"
Bare.decode(output, schema)
=> {3=>"Ut-oh"}
```
```ruby
schema = Bare.Map(Bare.Uint, Bare.String)
output = Bare.encode({3 => "Ut-oh", 3 => "Noway"}, schema)
puts output.inspect
=> "\x01\x03\x05Noway"
```

### union
Unions can represent one type in a set of types. When encoding a union you must specify what type you are encoding as a hash.

Unions also must enumerate their types as positive integers. 

Unions cannot have the same type twice.
```ruby
schema = Bare.Union({1 => Bare.Uint, 5 => Bare.U16})
output = Bare.encode({type: Bare.U16, value: 6}, schema)
puts output.inspect
=> "\x05\x06\x00"
decoded = Bare.decode(output, schema)
puts decoded.inspect
=> {:value=>5, :type=>#<BareTypes::U16:0x00007ffe9511ab70>}
decoded[:type] == Bare.U16
=> true
```

### struct
Structs are a collection of named fields. They are encoded and decoded as hashes. Order of keys in the hash matters.
Keys of these hashes must be a ruby symbol like `:this`

```ruby
schema = Bare.Struct({int: Bare.I8, uint: Bare.Uint })
output = Bare.encode({int: -5, uint: 8}, schema)
puts output.bytes.inspect
=> [251, 8]
Bare.decode(output, schema)
=> {:int=>-5, :uint=>8}
```

# Exceptions
### BareException
Includes all of the following

### VoidUsedOutsideTaggedSet
Occurs when void is used inappropriately. 

### MinimumSizeError
Occurs when too few args are passed to a type (eg.a struct with 0 fields)
 
### MaximumSizeError
Occurs when too a value can't be encoded in the maximum allowed space of a uint/int.

### MapKeyError
Map keys must use a primitive type which is not data or data<length>.
 
### EnumValueError
Occurs when an enum is passed two keys with the same value ie `{ 0 => :abc, 1 => :abc }`

### SchemaMismatch
Occurs in many cases when the data provided to encode doesn't match the schema.
