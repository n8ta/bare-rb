require '../bare-rb/lib/bare-rb'

encode_decode_tests = [
    # input, expected output, schema
    [1, "\x01".b, Bare::DataTypes::Uint.new],
    [127, "\x7F".b, Bare::DataTypes::Uint.new],
    [1, "\x01".b, Bare::DataTypes::Uint.new],
    [8, "\x08".b, Bare::DataTypes::Uint.new],
    [128, "\x80\x01".b, Bare::DataTypes::Uint.new],
    [129, "\x81\x01".b, Bare::DataTypes::Uint.new],
    [22369, "\xE1\xAE\x01".b, Bare::DataTypes::Uint.new],
    [16383,"\xFF\x7F".b, Bare::DataTypes::Uint.new],
    [16382,"\xFE\x7F".b, Bare::DataTypes::Uint.new],
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