require '../bare-rb/lib/bare-rb'

samples = [
    # input, expected output, schema
    [1, "\x01".b, Bare::DataTypes::U8.new],
    [3, "\x03".b, Bare::DataTypes::U8.new],
    [255, "\xFF".b, Bare::DataTypes::U8.new],

    [1, "\x01\x00".b, Bare::DataTypes::U16.new],
    [3, "\x03\x00".b, Bare::DataTypes::U16.new],
    [256, "\x00\x01".b, Bare::DataTypes::U16.new],
    [(2**16)-1, "\xFF\xFF".b, Bare::DataTypes::U16.new],

    [1, "\x01\x00\x00\x00".b, Bare::DataTypes::U32.new],
    [3, "\x03\x00\x00\x00".b, Bare::DataTypes::U32.new],
    [256+3, "\x03\x01\x00\x00".b, Bare::DataTypes::U32.new],
    [4278190080, "\x00\x00\x00\xFF".b, Bare::DataTypes::U32.new],
    [(2**32)-1, "\xFF\xFF\xFF\xFF".b, Bare::DataTypes::U32.new],

    [1, "\x01\x00\x00\x00\x00\x00\x00\x00".b, Bare::DataTypes::U64.new],
    [3, "\x03\x00\x00\x00\x00\x00\x00\x00".b, Bare::DataTypes::U64.new],
    [256+3, "\x03\x01\x00\x00\x00\x00\x00\x00".b, Bare::DataTypes::U64.new],
    [(2**64)-1, "\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF".b, Bare::DataTypes::U64.new],
    [(2**64)-2, "\xFE\xFF\xFF\xFF\xFF\xFF\xFF\xFF".b, Bare::DataTypes::U64.new],

    [1, "\x01".b, Bare::DataTypes::I8.new],
    [-1, "\xFF".b, Bare::DataTypes::I8.new],
    [3, "\x03".b, Bare::DataTypes::I8.new],
    [-3, "\xFD".b, Bare::DataTypes::I8.new],
    [-2**7, "\x80".b, Bare::DataTypes::I8.new],
    [(2**7)-1, "\x7F".b, Bare::DataTypes::I8.new],

    [1, "\x01\x00".b, Bare::DataTypes::I16.new],
    [-1, "\xFF\xFF".b, Bare::DataTypes::I16.new],
    [3, "\x03\x00".b, Bare::DataTypes::I16.new],
    [-3, "\xFD\xFF".b, Bare::DataTypes::I16.new],
    [-500, "\x0C\xFE".b, Bare::DataTypes::I16.new],
    [500, "\xF4\x01".b, Bare::DataTypes::I16.new],
    [-2**15, "\x00\x80".b, Bare::DataTypes::I16.new],
    [(2**15)-1, "\x7F\xFF".b, Bare::DataTypes::I8.new],


]

samples.each_with_index do  |sample,i|
  output = Bare.encode(sample[0], sample[2])
  if output != sample[1]
    raise "Test #{i.to_s} (#{sample[2].class.name}) failed real output: #{output.inspect} doesn't match expected output: #{sample[1].inspect}"
  end
  decoded = Bare.decode(output, sample[2])
  if decoded != sample[0]
    raise "Test #{i.to_s} (#{sample[2].class.name}) failed, decode #{decoded.inspect} doesn't match input #{sample[0].inspect}"
  end
end