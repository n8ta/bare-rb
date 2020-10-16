require '../src/lib/bare-rb'
starting = Time.now

testing_hash = {1 => "abc", 5 => :cow, 16382 => 123}

struct_def = {int: Bare.U8, uint: Bare.Uint, enum: Bare.Enum(testing_hash)}
struct_def2 = {int: Bare.U8,
               arr: Bare.ArrayFixedLen(Bare.U8, 3),
               uint: Bare.Uint,
               enum: Bare.Enum(testing_hash)}

# input, expected output, schema
encode_decode_tests = [
    [true, "\xFF\xFF".b, Bare.Bool],
    [false, "\x00\x00".b, Bare.Bool],\

    [5, "\x00\x00\xa0\x40".b, Bare.F32],
    [1337, "\x00\x20\xa7\x44".b, Bare.F32],
    [2**18, "\x00\x00\x80\x48".b, Bare.F32],

    [5, "\x00\x00\x00\x00\x00\x00\x14\x40".b, Bare.F64],
    [1337.1337, "\xe7\x1d\xa7\xe8\x88\xe4\x94\x40".b, Bare.F64],
    [2**18, "\x00\x00\x00\x00\x00\x00\x10\x41".b, Bare.F64],

    [1, "\x01".b, Bare.U8],
    [3, "\x03".b, Bare.U8],
    [255, "\xFF".b, Bare.U8],

    [1, "\x01\x00".b, Bare.U16],
    [3, "\x03\x00".b, Bare.U16],
    [256, "\x00\x01".b, Bare.U16],
    [(2 ** 16) - 1, "\xFF\xFF".b, Bare.U16],

    [1, "\x01\x00\x00\x00".b, Bare.U32],
    [3, "\x03\x00\x00\x00".b, Bare.U32],
    [256 + 3, "\x03\x01\x00\x00".b, Bare.U32],
    [4278190080, "\x00\x00\x00\xFF".b, Bare.U32],
    [(2 ** 32) - 1, "\xFF\xFF\xFF\xFF".b, Bare.U32],

    [1, "\x01\x00\x00\x00\x00\x00\x00\x00".b, Bare.U64],
    [3, "\x03\x00\x00\x00\x00\x00\x00\x00".b, Bare.U64],
    [256 + 3, "\x03\x01\x00\x00\x00\x00\x00\x00".b, Bare.U64],
    [(2 ** 64) - 1, "\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF".b, Bare.U64],
    [(2 ** 64) - 2, "\xFE\xFF\xFF\xFF\xFF\xFF\xFF\xFF".b, Bare.U64],

    [1, "\x01".b, Bare.I8],
    [-1, "\xFF".b, Bare.I8],
    [3, "\x03".b, Bare.I8],
    [-3, "\xFD".b, Bare.I8],
    [-2 ** 7, "\x80".b, Bare.I8],
    [(2 ** 7) - 1, "\x7F".b, Bare.I8],

    [1, "\x01\x00".b, Bare.I16],
    [-1, "\xFF\xFF".b, Bare.I16],
    [3, "\x03\x00".b, Bare.I16],
    [-3, "\xFD\xFF".b, Bare.I16],
    [-500, "\x0C\xFE".b, Bare.I16],
    [500, "\xF4\x01".b, Bare.I16],
    [-2 ** 15, "\x00\x80".b, Bare.I16],
    [(2 ** 15) - 1, "\xFF\x7F".b, Bare.I16],

    [1, "\x01\x00\x00\x00".b, Bare.I32],
    [-1, "\xFF\xFF\xFF\xFF".b, Bare.I32],
    [3, "\x03\x00\x00\x00".b, Bare.I32],
    [-3, "\xFD\xFF\xFF\xFF".b, Bare.I32],
    [-500, "\x0C\xFE\xFF\xFF".b, Bare.I32],
    [-5000000, "\xC0\xB4\xB3\xFF".b, Bare.I32],
    [500, "\xF4\x01\x00\x00".b, Bare.I32],
    [-2 ** 31, "\x00\x00\x00\x80".b, Bare.I32],
    [(2 ** 31) - 1, "\xFF\xFF\xFF\x7F".b, Bare.I32],

    [1, "\x01\x00\x00\x00\x00\x00\x00\x00".b, Bare.I64],
    [-1, "\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF".b, Bare.I64],
    [3, "\x03\x00\x00\x00\x00\x00\x00\x00".b, Bare.I64],
    [-3, "\xFD\xFF\xFF\xFF\xFF\xFF\xFF\xFF".b, Bare.I64],
    [-500, "\x0C\xFE\xFF\xFF\xFF\xFF\xFF\xFF".b, Bare.I64],
    [-5000000, "\xC0\xB4\xB3\xFF\xFF\xFF\xFF\xFF".b, Bare.I64],
    [500, "\xF4\x01\x00\x00\x00\x00\x00\x00".b, Bare.I64],
    [-2 ** 63, "\x00\x00\x00\x00\x00\x00\x00\x80".b, Bare.I64],
    [(2 ** 63) - 1, "\xFF\xFF\xFF\xFF\xFF\xFF\xFF\x7F".b, Bare.I64],
    [-50000000000000000, "\x00\x00\x3B\xD1\x43\x5D\x4E\xFF".b, Bare.I64],

    [127, "\x7F".b, Bare.Uint],
    [1, "\x01".b, Bare.Uint],
    [8, "\x08".b, Bare.Uint],
    [128, "\x80\x01".b, Bare.Uint],
    [129, "\x81\x01".b, Bare.Uint],
    [22369, "\xE1\xAE\x01".b, Bare.Uint],
    [16383, "\xFF\x7F".b, Bare.Uint],
    [16382, "\xFE\x7F".b, Bare.Uint],

    [[1, 2, 3], "\x01\x02\x03".b, Bare.ArrayFixedLen(Bare.U8, 3)],

    [[-3, -500, -5000000], "\xFD\xFF\xFF\xFF\xFF\xFF\xFF\xFF\x0C\xFE\xFF\xFF\xFF\xFF\xFF\xFF\xC0\xB4\xB3\xFF\xFF\xFF\xFF\xFF".b, Bare.ArrayFixedLen(Bare.I64, 3)],
    [[127, 22369, 16383, 16382], "\x7F\xE1\xAE\x01\xFF\x7F\xFE\x7F".b, Bare.ArrayFixedLen(Bare.Uint, 4)],

    [[:cow, "abc", 123], "\x05\x01\xFE\x7F".b, Bare.ArrayFixedLen(Bare.Enum(testing_hash), 3)],
    [:cow, "\x05".b, Bare.Enum(testing_hash)],
    ["abc", "\x01".b, Bare.Enum(testing_hash)],
    [123, "\xFE\x7F".b, Bare.Enum(testing_hash)],


    [[:cow, 123, "abc", 123], "\x05\xFE\x7F\x01\xFE\x7F".b, Bare.ArrayFixedLen(Bare.Enum(testing_hash), 4)],
    [[[1, 2, 3], [4, 5, 6]], "\x01\x02\x03\x04\x05\x06".b, Bare.ArrayFixedLen(Bare.ArrayFixedLen(Bare.U8, 3), 2)],

    ["\xFF\xFF\x00\x00".b, "\x04\xFF\xFF\x00\x00".b, Bare.Data],
    ["\xFF\xFF\x00\x00\xFF\xFF".b, "\x06\xFF\xFF\x00\x00\xFF\xFF".b, Bare.Data],

    ["\xFF\xFF\x00\x00".b, "\xFF\xFF\x00\x00".b, Bare.DataFixedLen(4)],
    ["\xFF\xFF\x00\x00\xFF\xFF".b, "\xFF\xFF\x00\x00\xFF\xFF".b, Bare.DataFixedLen(6)],

    [{type: Bare.Uint, value: 5}, "\x00\x05".b, Bare.Union({0 => Bare.Uint, 1 => Bare.U16})],
    [{type: Bare.U16, value: 5}, "\x01\x05\x00".b, Bare.Union({0 => Bare.Uint, 1 => Bare.U16})],
    [{type: Bare.DataFixedLen(6), value: "\xFF\xFF\x00\x00\xFF\xFF".b}, "\x04\xFF\xFF\x00\x00\xFF\xFF".b, Bare.Union({4 => Bare.DataFixedLen(6)})],
    [{type: Bare.DataFixedLen(6), value: "\xFF\xFF\x00\x00\xFF\xFF".b}, "\x09\xFF\xFF\x00\x00\xFF\xFF".b, Bare.Union({4 => Bare.Uint, 9 => Bare.DataFixedLen(6)})],

    [[3, 5, 6, 7], "\x04\x03\x05\x06\x07".b, Bare.Array(Bare.U8)],
    [[[1, 2, 3], [4, 5, 6, 8]], "\x02\x03\x01\x02\x03\x04\x04\x05\x06\x08".b, Bare.Array(Bare.Array(Bare.U8))],

    [{int: 1, uint: 16382, enum: :cow}, "\x01\xFE\x7F\x05".b, Bare.Struct(struct_def)],
    [{enum: :cow, uint: 16382, int: 1}, "\x01\xFE\x7F\x05".b, Bare.Struct(struct_def)],
    [{int: 1, arr: [9,8,7], uint: 5, enum: "abc"}, "\x01\x09\x08\x07\x05\x01".b, Bare.Struct(struct_def2)],

    [{8 => 16, 5 => 10 }, "\x02\x08\x10\x00\x05\x0A\x00".b, Bare.Map(Bare.U8, Bare.U16)],
    [{8 => "abc", 6 => :cow }, "\x02\x08\x01\x06\x05".b, Bare.Map(Bare.U8, Bare.Enum(testing_hash))],
    [{preInt: 4, theMap: {8 => 16, 5 => 10 }, postInt: 5}, "\x04\x02\x08\x10\x00\x05\x0A\x00\x05".b, Bare.Struct({preInt: Bare.U8, :theMap => Bare.Map(Bare.U8, Bare.U16), postInt: Bare.U8 })],

    [nil, "\x00".b, Bare.Optional(Bare.U8)],
    [1, "\xFF\x01".b, Bare.Optional(Bare.U8)],
    [{preInt: 4, theMap: {8 => 16, 5 => 10 }, postInt: 5}, "\xFF\x04\x02\x08\x10\x00\x05\x0A\x00\x05".b, Bare.Optional(Bare.Struct({preInt: Bare.U8, :theMap => Bare.Map(Bare.U8, Bare.U16), postInt: Bare.U8 }))],
    [{preInt: 4, opt: nil, postInt: 5}, "\x04\x00\x05".b, Bare.Struct({preInt: Bare.U8, :opt => Bare.Optional(Bare.U8), postInt: Bare.U8 })],
    [{preInt: 4, opt: 9, postInt: 5}, "\x04\xFF\x09\x05".b, Bare.Struct({preInt: Bare.U8, :opt => Bare.Optional(Bare.U8), postInt: Bare.U8 })],

    ["ABC", "\x03\x41\x42\x43".b, Bare.String],
    ["A C", "\x03\x41\x20\x43".b, Bare.String],
    ["😊", "\x04\xF0\x9F\x98\x8A".b, Bare.String],
    ["😊ABC😊", "\x0B\xF0\x9F\x98\x8A\x41\x42\x43\xF0\x9F\x98\x8A".b, Bare.String],
    [{preInt: 4, str: "😊ABC😊", postInt: 5}, "\x04\x0B\xF0\x9F\x98\x8A\x41\x42\x43\xF0\x9F\x98\x8A\x05".b, Bare.Struct({preInt: Bare.U8, :str => Bare.String, postInt: Bare.U8 })],
    [{preInt: 4, str: " 😊ABC😊 ", postInt: 5}, "\x04\x0D\x20\xF0\x9F\x98\x8A\x41\x42\x43\xF0\x9F\x98\x8A\x20\x05".b, Bare.Struct({preInt: Bare.U8, :str => Bare.String, postInt: Bare.U8 })],

    [{type: Bare.Void}, "\x01".b, Bare.Union({0 => Bare.Uint, 1 => Bare.Void})],
    [{type: Bare.Uint, value: 5}, "\x00\x05".b, Bare.Union({0 => Bare.Uint, 1 => Bare.Void})],


]

decode_tests = [
    ["\x05\x00".b, true, Bare.Bool],
    ["\x00\x70".b, true, Bare.Bool],
    ["\x00\x00".b, false, Bare.Bool],
]

encode_decode_tests.each_with_index do |sample, i|
  begin
    output = Bare.encode(sample[0], sample[2])
    if output != sample[1]
      raise "\nTest #{sample[0]} - ##{i.to_s} (#{sample[2].class.name}) failed\nreal output: #{output.inspect} \ndoesn't match expected output: #{sample[1].inspect}"
    end
    decoded = Bare.decode(output, sample[2])
    if decoded.is_a?(Hash)
      decoded.keys.each do |key|
        decodedVal = decoded[key]
        raise("\nTest #{sample[0]} - ##{i.to_s}\nDifference found in enum\n#{decodedVal.inspect} != #{sample[0][key].inspect}") if decodedVal != sample[0][key]
      end
    elsif decoded != sample[0]
      raise "\nTest #{sample[0]} - ##{i.to_s} (#{sample[2].class.name}) failed\n#{sample[0].inspect} <- input\n#{output} <- encoded \n#{decoded.inspect} <- decoded \n"
    end
  rescue Exception => e
    raise("\nTest #{sample[0]} - ##{i.to_s} (#{sample[2].class.name}) failed")
    puts e.inspect
  end
end

decode_tests.each_with_index do |test, i|
  decoded = Bare.decode(test[0], test[2])
  if decoded != test[1]
    raise "\nDecode Test #{test[0]} - ##{i.to_s} (#{test[2].class.name}) failed\n decoding #{test[0].inspect} isn't equal to  #{test[1].inspect}\n instead got #{decoded.inspect}"
  end
end

ending = Time.now

elapsed = ending - starting

puts "\n#{encode_decode_tests.size + decode_tests.size} tests \e[#{32}mPASSED\e[0m in #{elapsed} seconds\n"