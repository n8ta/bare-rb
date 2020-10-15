require '../bare-rb/lib/bare-rb'

testing_hash = Hash.new
testing_hash[1] = "abc"
testing_hash[5] = :cow
testing_hash[16382] = 123

binaryData = "\x01\x80"
12

# input, expected output, schema
encode_decode_tests = [
    [true, "\xFF\xFF".b, Bare::Bool.new],
    [false, "\x00\x00".b, Bare::Bool.new],

    [1, "\x01".b, Bare::U8.new],
    [3, "\x03".b, Bare::U8.new],
    [255, "\xFF".b, Bare::U8.new],

    [1, "\x01\x00".b, Bare::U16.new],
    [3, "\x03\x00".b, Bare::U16.new],
    [256, "\x00\x01".b, Bare::U16.new],
    [(2 ** 16) - 1, "\xFF\xFF".b, Bare::U16.new],

    [1, "\x01\x00\x00\x00".b, Bare::U32.new],
    [3, "\x03\x00\x00\x00".b, Bare::U32.new],
    [256 + 3, "\x03\x01\x00\x00".b, Bare::U32.new],
    [4278190080, "\x00\x00\x00\xFF".b, Bare::U32.new],
    [(2 ** 32) - 1, "\xFF\xFF\xFF\xFF".b, Bare::U32.new],

    [1, "\x01\x00\x00\x00\x00\x00\x00\x00".b, Bare::U64.new],
    [3, "\x03\x00\x00\x00\x00\x00\x00\x00".b, Bare::U64.new],
    [256 + 3, "\x03\x01\x00\x00\x00\x00\x00\x00".b, Bare::U64.new],
    [(2 ** 64) - 1, "\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF".b, Bare::U64.new],
    [(2 ** 64) - 2, "\xFE\xFF\xFF\xFF\xFF\xFF\xFF\xFF".b, Bare::U64.new],

    [1, "\x01".b, Bare::I8.new],
    [-1, "\xFF".b, Bare::I8.new],
    [3, "\x03".b, Bare::I8.new],
    [-3, "\xFD".b, Bare::I8.new],
    [-2 ** 7, "\x80".b, Bare::I8.new],
    [(2 ** 7) - 1, "\x7F".b, Bare::I8.new],

    [1, "\x01\x00".b, Bare::I16.new],
    [-1, "\xFF\xFF".b, Bare::I16.new],
    [3, "\x03\x00".b, Bare::I16.new],
    [-3, "\xFD\xFF".b, Bare::I16.new],
    [-500, "\x0C\xFE".b, Bare::I16.new],
    [500, "\xF4\x01".b, Bare::I16.new],
    [-2 ** 15, "\x00\x80".b, Bare::I16.new],
    [(2 ** 15) - 1, "\xFF\x7F".b, Bare::I16.new],

    [1, "\x01\x00\x00\x00".b, Bare::I32.new],
    [-1, "\xFF\xFF\xFF\xFF".b, Bare::I32.new],
    [3, "\x03\x00\x00\x00".b, Bare::I32.new],
    [-3, "\xFD\xFF\xFF\xFF".b, Bare::I32.new],
    [-500, "\x0C\xFE\xFF\xFF".b, Bare::I32.new],
    [-5000000, "\xC0\xB4\xB3\xFF".b, Bare::I32.new],
    [500, "\xF4\x01\x00\x00".b, Bare::I32.new],
    [-2 ** 31, "\x00\x00\x00\x80".b, Bare::I32.new],
    [(2 ** 31) - 1, "\xFF\xFF\xFF\x7F".b, Bare::I32.new],

    [1, "\x01\x00\x00\x00\x00\x00\x00\x00".b, Bare::I64.new],
    [-1, "\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF".b, Bare::I64.new],
    [3, "\x03\x00\x00\x00\x00\x00\x00\x00".b, Bare::I64.new],
    [-3, "\xFD\xFF\xFF\xFF\xFF\xFF\xFF\xFF".b, Bare::I64.new],
    [-500, "\x0C\xFE\xFF\xFF\xFF\xFF\xFF\xFF".b, Bare::I64.new],
    [-5000000, "\xC0\xB4\xB3\xFF\xFF\xFF\xFF\xFF".b, Bare::I64.new],
    [500, "\xF4\x01\x00\x00\x00\x00\x00\x00".b, Bare::I64.new],
    [-2 ** 63, "\x00\x00\x00\x00\x00\x00\x00\x80".b, Bare::I64.new],
    [(2 ** 63) - 1, "\xFF\xFF\xFF\xFF\xFF\xFF\xFF\x7F".b, Bare::I64.new],
    [-50000000000000000, "\x00\x00\x3B\xD1\x43\x5D\x4E\xFF".b, Bare::I64.new],

    [127, "\x7F".b, Bare::Uint.new],
    [1, "\x01".b, Bare::Uint.new],
    [8, "\x08".b, Bare::Uint.new],
    [128, "\x80\x01".b, Bare::Uint.new],
    [129, "\x81\x01".b, Bare::Uint.new],
    [22369, "\xE1\xAE\x01".b, Bare::Uint.new],
    [16383, "\xFF\x7F".b, Bare::Uint.new],
    [16382, "\xFE\x7F".b, Bare::Uint.new],

    [[1, 2, 3], "\x01\x02\x03".b, Bare::ArrayFixedLen.new(Bare::U8.new, 3)],

    [[-3, -500, -5000000], "\xFD\xFF\xFF\xFF\xFF\xFF\xFF\xFF\x0C\xFE\xFF\xFF\xFF\xFF\xFF\xFF\xC0\xB4\xB3\xFF\xFF\xFF\xFF\xFF".b, Bare::ArrayFixedLen.new(Bare::I64.new, 3)],
    [[127, 22369, 16383, 16382], "\x7F\xE1\xAE\x01\xFF\x7F\xFE\x7F".b, Bare::ArrayFixedLen.new(Bare::Uint.new, 4)],

    [[:cow, "abc", 123], "\x05\x01\xFE\x7F".b, Bare::ArrayFixedLen.new(Bare::Enum.new(testing_hash), 3)],
    [:cow, "\x05".b, Bare::Enum.new(testing_hash)],
    ["abc", "\x01".b, Bare::Enum.new(testing_hash)],
    [123, "\xFE\x7F".b, Bare::Enum.new(testing_hash)],


    [[:cow, 123, "abc", 123], "\x05\xFE\x7F\x01\xFE\x7F".b, Bare::ArrayFixedLen.new(Bare::Enum.new(testing_hash), 4)],
    [[[1,2,3],[4,5,6]], "\x01\x02\x03\x04\x05\x06".b, Bare::ArrayFixedLen.new(Bare::ArrayFixedLen.new(Bare::U8.new, 3), 2)],

    ["\xFF\xFF\x00\x00".b , "\x04\xFF\xFF\x00\x00".b, Bare::Data.new],
    ["\xFF\xFF\x00\x00\xFF\xFF".b , "\x06\xFF\xFF\x00\x00\xFF\xFF".b, Bare::Data.new],

    ["\xFF\xFF\x00\x00".b , "\xFF\xFF\x00\x00".b, Bare::DataFixedLen.new(4)],
    ["\xFF\xFF\x00\x00\xFF\xFF".b , "\xFF\xFF\x00\x00\xFF\xFF".b, Bare::DataFixedLen.new(6)],
]

decode_tests = [
    ["\x05\x00".b, true, Bare::Bool.new],
    ["\x00\x70".b, true, Bare::Bool.new],
    ["\x00\x00".b, false, Bare::Bool.new],
]

encode_decode_tests.each_with_index do |sample, i|
  begin
  output = Bare.encode(sample[0], sample[2])
  if output != sample[1]
    raise "\nTest #{sample[0]} - ##{i.to_s} (#{sample[2].class.name}) failed\nreal output: #{output.inspect} \ndoesn't match expected output: #{sample[1].inspect}"
  end
  decoded = Bare.decode(output, sample[2])
  if decoded != sample[0]
    raise "\nTest #{sample[0]} - ##{i.to_s} (#{sample[2].class.name}) failed\n decode #{decoded.inspect} \ndoesn't match input #{sample[0].inspect}"
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