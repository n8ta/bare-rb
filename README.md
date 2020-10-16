# BARE-RB

WIP Implementation of the BARE message protocol in Ruby

Bare spec:

https://baremessages.org


# Example
```ruby
schema = Bare.Array(Bare.U8) # Array of unsigned 1 byte integers
output = Bare.encode([1,2,3,4], schema)
puts output.inspect
=> "\x04\x01\x02\x03\x04".b
Bare.decode(output, schema) # You must know what schema was used to encdoe data to decode it
=> [1,2,3,4]
```

# Todo List
0. proper errors
1. int
2. f32, f64
3. string,
4. void
5. **Lexer and Parser**

# Done List
0. uint
1. u8, u16, u32, u64
2. i8, i16, i32, i64
3. bool
4. enum
5. fix length array
6. suitable encode/decode framework
7. data[length]
8. data
9. variable length array
10. union
11. struct
12. map
13. optional

