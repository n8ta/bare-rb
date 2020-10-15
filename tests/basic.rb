require '../bare-rb/lib/bare-rb'

testing_hash = Hash.new
testing_hash[1] = "abc"
testing_hash[5] = :cow
testing_hash[16382] = 123

encode_decode_tests = [
    # input, expected output, schema
    #
    [true, "\xFF\xFF".b, Bare::DataTypes::Bool.new],
    [false, "\x00\x00".b, Bare::DataTypes::Bool.new],

    [1, "\x01".b, Bare::DataTypes::U8.new],
    [3, "\x03".b, Bare::DataTypes::U8.new],
    [255, "\xFF".b, Bare::DataTypes::U8.new],

    [1, "\x01\x00".b, Bare::DataTypes::U16.new],
    [3, "\x03\x00".b, Bare::DataTypes::U16.new],
    [256, "\x00\x01".b, Bare::DataTypes::U16.new],
    [(2 ** 16) - 1, "\xFF\xFF".b, Bare::DataTypes::U16.new],

    [1, "\x01\x00\x00\x00".b, Bare::DataTypes::U32.new],
    [3, "\x03\x00\x00\x00".b, Bare::DataTypes::U32.new],
    [256 + 3, "\x03\x01\x00\x00".b, Bare::DataTypes::U32.new],
    [4278190080, "\x00\x00\x00\xFF".b, Bare::DataTypes::U32.new],
    [(2 ** 32) - 1, "\xFF\xFF\xFF\xFF".b, Bare::DataTypes::U32.new],

    [1, "\x01\x00\x00\x00\x00\x00\x00\x00".b, Bare::DataTypes::U64.new],
    [3, "\x03\x00\x00\x00\x00\x00\x00\x00".b, Bare::DataTypes::U64.new],
    [256 + 3, "\x03\x01\x00\x00\x00\x00\x00\x00".b, Bare::DataTypes::U64.new],
    [(2 ** 64) - 1, "\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF".b, Bare::DataTypes::U64.new],
    [(2 ** 64) - 2, "\xFE\xFF\xFF\xFF\xFF\xFF\xFF\xFF".b, Bare::DataTypes::U64.new],

    [1, "\x01".b, Bare::DataTypes::I8.new],
    [-1, "\xFF".b, Bare::DataTypes::I8.new],
    [3, "\x03".b, Bare::DataTypes::I8.new],
    [-3, "\xFD".b, Bare::DataTypes::I8.new],
    [-2 ** 7, "\x80".b, Bare::DataTypes::I8.new],
    [(2 ** 7) - 1, "\x7F".b, Bare::DataTypes::I8.new],

    [1, "\x01\x00".b, Bare::DataTypes::I16.new],
    [-1, "\xFF\xFF".b, Bare::DataTypes::I16.new],
    [3, "\x03\x00".b, Bare::DataTypes::I16.new],
    [-3, "\xFD\xFF".b, Bare::DataTypes::I16.new],
    [-500, "\x0C\xFE".b, Bare::DataTypes::I16.new],
    [500, "\xF4\x01".b, Bare::DataTypes::I16.new],
    [-2 ** 15, "\x00\x80".b, Bare::DataTypes::I16.new],
    [(2 ** 15) - 1, "\xFF\x7F".b, Bare::DataTypes::I16.new],

    [1, "\x01\x00\x00\x00".b, Bare::DataTypes::I32.new],
    [-1, "\xFF\xFF\xFF\xFF".b, Bare::DataTypes::I32.new],
    [3, "\x03\x00\x00\x00".b, Bare::DataTypes::I32.new],
    [-3, "\xFD\xFF\xFF\xFF".b, Bare::DataTypes::I32.new],
    [-500, "\x0C\xFE\xFF\xFF".b, Bare::DataTypes::I32.new],
    [-5000000, "\xC0\xB4\xB3\xFF".b, Bare::DataTypes::I32.new],
    [500, "\xF4\x01\x00\x00".b, Bare::DataTypes::I32.new],
    [-2 ** 31, "\x00\x00\x00\x80".b, Bare::DataTypes::I32.new],
    [(2 ** 31) - 1, "\xFF\xFF\xFF\x7F".b, Bare::DataTypes::I32.new],

    [1, "\x01\x00\x00\x00\x00\x00\x00\x00".b, Bare::DataTypes::I64.new],
    [-1, "\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF".b, Bare::DataTypes::I64.new],
    [3, "\x03\x00\x00\x00\x00\x00\x00\x00".b, Bare::DataTypes::I64.new],
    [-3, "\xFD\xFF\xFF\xFF\xFF\xFF\xFF\xFF".b, Bare::DataTypes::I64.new],
    [-500, "\x0C\xFE\xFF\xFF\xFF\xFF\xFF\xFF".b, Bare::DataTypes::I64.new],
    [-5000000, "\xC0\xB4\xB3\xFF\xFF\xFF\xFF\xFF".b, Bare::DataTypes::I64.new],
    [500, "\xF4\x01\x00\x00\x00\x00\x00\x00".b, Bare::DataTypes::I64.new],
    [-2 ** 63, "\x00\x00\x00\x00\x00\x00\x00\x80".b, Bare::DataTypes::I64.new],
    [(2 ** 63) - 1, "\xFF\xFF\xFF\xFF\xFF\xFF\xFF\x7F".b, Bare::DataTypes::I64.new],
    [-50000000000000000, "\x00\x00\x3B\xD1\x43\x5D\x4E\xFF".b, Bare::DataTypes::I64.new],

    [127, "\x7F".b, Bare::DataTypes::Uint.new],
    [1, "\x01".b, Bare::DataTypes::Uint.new],
    [8, "\x08".b, Bare::DataTypes::Uint.new],
    [128, "\x80\x01".b, Bare::DataTypes::Uint.new],
    [129, "\x81\x01".b, Bare::DataTypes::Uint.new],
    [22369, "\xE1\xAE\x01".b, Bare::DataTypes::Uint.new],
    [16383, "\xFF\x7F".b, Bare::DataTypes::Uint.new],
    [16382, "\xFE\x7F".b, Bare::DataTypes::Uint.new],

    [[1, 2, 3], "\x01\x02\x03".b, Bare::DataTypes::FixedLenArray.new(Bare::DataTypes::U8.new, 3)],

    [[-3, -500, -5000000],
     "\xFD\xFF\xFF\xFF\xFF\xFF\xFF\xFF\x0C\xFE\xFF\xFF\xFF\xFF\xFF\xFF\xC0\xB4\xB3\xFF\xFF\xFF\xFF\xFF".b,
     Bare::DataTypes::FixedLenArray.new(Bare::DataTypes::I64.new, 3)],
    [[127, 22369, 16383, 16382], "\x7F\xE1\xAE\x01\xFF\x7F\xFE\x7F".b,
     Bare::DataTypes::FixedLenArray.new(Bare::DataTypes::Uint.new, 4)],

    [:cow, "\x01".b, Bare::DataTypes::Enum.new(["abc", :cow, 123])],
    ["abc", "\x00".b, Bare::DataTypes::Enum.new(["abc", :cow, 123])],
    [123, "\x02".b, Bare::DataTypes::Enum.new(["abc", :cow, 123])],
    [[:cow, "abc", 123], "\x01\x00\x02".b, Bare::DataTypes::FixedLenArray.new(Bare::DataTypes::Enum.new(["abc", :cow, 123]), 3)],
    [:cow, "\x05".b, Bare::DataTypes::Enum.new(testing_hash)],
    ["abc", "\x01".b, Bare::DataTypes::Enum.new(testing_hash)],
    [123, "\xFE\x7F".b, Bare::DataTypes::Enum.new(testing_hash)],


    [[:cow, 123, "abc", 123], "\x05\xFE\x7F\x01\xFE\x7F".b, Bare::DataTypes::FixedLenArray.new(Bare::DataTypes::Enum.new(testing_hash), 4)],


]

decode_tests = [
    ["\x05\x00".b, true, Bare::DataTypes::Bool.new],
    ["\x00\x70".b, true, Bare::DataTypes::Bool.new],
    ["\x00\x00".b, false, Bare::DataTypes::Bool.new],
]

encode_decode_tests.each_with_index do |sample, i|
  output = Bare.encode(sample[0], sample[2])
  if output != sample[1]
    raise "\nTest #{sample[0]} - ##{i.to_s} (#{sample[2].class.name}) failed\nreal output: #{output.inspect} \ndoesn't match expected output: #{sample[1].inspect}"
  end
  decoded = Bare.decode(output, sample[2])
  if decoded != sample[0]
    raise "\nTest #{sample[0]} - ##{i.to_s} (#{sample[2].class.name}) failed\n decode #{decoded.inspect} \ndoesn't match input #{sample[0].inspect}"
  end
end

decode_tests.each_with_index do |test, i|
  decoded = Bare.decode(test[0], test[2])
  if decoded != test[1]
    raise "\nDecode Test #{test[0]} - ##{i.to_s} (#{test[2].class.name}) failed\n decoding #{test[0].inspect} isn't equal to  #{test[1].inspect}\n instead got #{decoded.inspect}"
  end
end