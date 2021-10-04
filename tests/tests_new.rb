require "minitest/autorun"

def rel_path(path)
  File.join(File.dirname(__FILE__), path)
end

require_relative '../src/lib/bare-rb'

def set_text_encoding(input)
  if input.is_a?(String) and input.encoding == Encoding::ASCII_8BIT
    input.force_encoding(Encoding::US_ASCII)
  else
    input
  end
end

class TestBare < Minitest::Test
  def enc_dec(array)
    array.each do |test|
      input = test[0] # 5
      oracle_binary = test[1] # "\x00x01\x03"
      schema = test[2] # Bare.Watever()

      binary_encoded = Bare.encode(input, schema)
      assert_equal binary_encoded.force_encoding('ASCII-8BIT'),
                   oracle_binary.force_encoding('ASCII-8BIT'),
                   "Binary doesn't match oracle binary input:#{test[0]}"
      output = Bare.decode(binary_encoded, schema)
      output_oracle = Bare.decode(oracle_binary, schema)

      assert_equal set_text_encoding(input), set_text_encoding(output), "decode(encode(init)) != init #{test[0]}"
      assert_equal set_text_encoding(input), set_text_encoding(output), "decode(encode(init)) != init #{test[0]}"
      a = set_text_encoding(output_oracle)
      b = set_text_encoding(output)
      assert_equal a, b, "decode(encode(init)) != oracle output\n #{input}"
    end
  end

  def test_float32
    self.enc_dec([
                   [5, "\x00\x00\xa0\x40".b, Bare.F32],
                   [1337, "\x00\x20\xa7\x44".b, Bare.F32],
                   [2 ** 18, "\x00\x00\x80\x48".b, Bare.F32],
                 ])
  end

  def test_float64
    self.enc_dec([
                   [5, "\x00\x00\x00\x00\x00\x00\x14\x40".b, Bare.F64],
                   [1337.1337, "\xe7\x1d\xa7\xe8\x88\xe4\x94\x40".b, Bare.F64],
                   [2 ** 18, "\x00\x00\x00\x00\x00\x00\x10\x41".b, Bare.F64],])
  end

  def test_array_uint
    self.enc_dec(
      [
        [[1], "\x01\x01".b, Bare.Array(Bare.Uint)],
        [[1, 8], "\x02\x01\x08".b, Bare.Array(Bare.Uint)],
        [[1, 8, 128, 129, 22369, 16383, 16382], "\x07\x01\x08\x80\x01\x81\x01\xE1\xAE\x01\xFF\x7F\xFE\x7F".b, Bare.Array(Bare.Uint)],
      ]
    )
  end

  def test_uint
    self.enc_dec([
                   [127, "\x7F".b, Bare.Uint],
                   [1, "\x01".b, Bare.Uint],
                   [8, "\x08".b, Bare.Uint],
                   [128, "\x80\x01".b, Bare.Uint],
                   [129, "\x81\x01".b, Bare.Uint],
                   [22369, "\xE1\xAE\x01".b, Bare.Uint],
                   [16383, "\xFF\x7F".b, Bare.Uint],
                   [16382, "\xFE\x7F".b, Bare.Uint],
                 ])
  end

  def test_int
    self.enc_dec([
                   [0, "\x00", Bare.Int],
                   # [-1, "\x01", Bare.Int],
                   [1, "\x02", Bare.Int],
                   [-2, "\x03", Bare.Int],
                   [2, "\x04", Bare.Int],
                   [-3, "\x05", Bare.Int],
                   [22369, "\xC2\xDD\x02".b, Bare.Int],
                   [-22369, "\xC1\xDD\x02".b, Bare.Int]
                 ])
  end

  def test_bool
    self.enc_dec([
                   [true, "\x00".b, Bare.Bool],
                   [false, "\x01".b, Bare.Bool]]
    )
  end

  def test_u8
    self.enc_dec([[1, "\x01".b, Bare.U8],
                  [3, "\x03".b, Bare.U8],
                  [255, "\xFF".b, Bare.U8]])
  end

  def test_u16
    self.enc_dec([
                   [1, "\x01\x00".b, Bare.U16],
                   [3, "\x03\x00".b, Bare.U16],
                   [256, "\x00\x01".b, Bare.U16],
                   [(2 ** 16) - 1, "\xFF\xFF".b, Bare.U16],

                 ])
  end

  def test_u32
    self.enc_dec([
                   [1, "\x01\x00\x00\x00".b, Bare.U32],
                   [3, "\x03\x00\x00\x00".b, Bare.U32],
                   [256 + 3, "\x03\x01\x00\x00".b, Bare.U32],
                   [4278190080, "\x00\x00\x00\xFF".b, Bare.U32],
                   [(2 ** 32) - 1, "\xFF\xFF\xFF\xFF".b, Bare.U32],
                 ])
  end

  def test_u64
    self.enc_dec([
                   [1, "\x01\x00\x00\x00\x00\x00\x00\x00".b, Bare.U64],
                   [3, "\x03\x00\x00\x00\x00\x00\x00\x00".b, Bare.U64],
                   [256 + 3, "\x03\x01\x00\x00\x00\x00\x00\x00".b, Bare.U64],
                 # removed temporarily due to issues with rutie and full 64 bit nums
                  [(2 ** 64) - 1, "\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF".b, Bare.U64],
                  [(2 ** 64) - 2, "\xFE\xFF\xFF\xFF\xFF\xFF\xFF\xFF".b, Bare.U64],

                 ])
  end

  def test_i8
    self.enc_dec([
                   [1, "\x01".b, Bare.I8],
                   [-1, "\xFF".b, Bare.I8],
                   [3, "\x03".b, Bare.I8],
                   [-3, "\xFD".b, Bare.I8],
                   [-2 ** 7, "\x80".b, Bare.I8],
                   [(2 ** 7) - 1, "\x7F".b, Bare.I8],
                 ])
  end

  def test_i16
    self.enc_dec([

                   [1, "\x01\x00".b, Bare.I16],
                   [-1, "\xFF\xFF".b, Bare.I16],
                   [3, "\x03\x00".b, Bare.I16],
                   [-3, "\xFD\xFF".b, Bare.I16],
                   [-500, "\x0C\xFE".b, Bare.I16],
                   [500, "\xF4\x01".b, Bare.I16],
                   [-2 ** 15, "\x00\x80".b, Bare.I16],
                   [(2 ** 15) - 1, "\xFF\x7F".b, Bare.I16],
                 ])
  end

  def test_i32
    self.enc_dec([

                   [1, "\x01\x00\x00\x00".b, Bare.I32],
                   [-1, "\xFF\xFF\xFF\xFF".b, Bare.I32],
                   [3, "\x03\x00\x00\x00".b, Bare.I32],
                   [-3, "\xFD\xFF\xFF\xFF".b, Bare.I32],
                   [-500, "\x0C\xFE\xFF\xFF".b, Bare.I32],
                   [-5000000, "\xC0\xB4\xB3\xFF".b, Bare.I32],
                   [500, "\xF4\x01\x00\x00".b, Bare.I32],
                   [-2 ** 31, "\x00\x00\x00\x80".b, Bare.I32],
                   [(2 ** 31) - 1, "\xFF\xFF\xFF\x7F".b, Bare.I32],
                 ])
  end

  def test_i64
    self.enc_dec([

                   [1, "\x01\x00\x00\x00\x00\x00\x00\x00".b, Bare.I64],
                   [-1, "\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF".b, Bare.I64],
                   [3, "\x03\x00\x00\x00\x00\x00\x00\x00".b, Bare.I64],
                   [-3, "\xFD\xFF\xFF\xFF\xFF\xFF\xFF\xFF".b, Bare.I64],
                   [-500, "\x0C\xFE\xFF\xFF\xFF\xFF\xFF\xFF".b, Bare.I64],
                   [-5000000, "\xC0\xB4\xB3\xFF\xFF\xFF\xFF\xFF".b, Bare.I64],
                   [500, "\xF4\x01\x00\x00\x00\x00\x00\x00".b, Bare.I64],
                   # TODO: SOMETHING IS WRONG THESE PASS IN THE RUBY VERSION
                   # [-2 ** 63, "\x00\x00\x00\x00\x00\x00\x00\x80".b, Bare.I64],
                   # [(2 ** 63) - 1, "\xFF\xFF\xFF\xFF\xFF\xFF\xFF\x7F".b, Bare.I64],
                   [-50000000000000000, "\x00\x00\x3B\xD1\x43\x5D\x4E\xFF".b, Bare.I64],
                 ])
  end

  def test_array_fix_len
    self.enc_dec([
                   [[1, 2, 3], "\x01\x02\x03".b, Bare.ArrayFixedLen(Bare.I8, 3)],
                   [[-3, -500, -5000000], "\xFD\xFF\xFF\xFF\xFF\xFF\xFF\xFF\x0C\xFE\xFF\xFF\xFF\xFF\xFF\xFF\xC0\xB4\xB3\xFF\xFF\xFF\xFF\xFF".b, Bare.ArrayFixedLen(Bare.I64, 3)],
                 ])

  end

  def _test_array_fix_len_plus
    testing_hash = { 1 => "abc", 5 => :cow, 16382 => 123 }
    self.enc_dec([
                   [[127, 22369, 16383, 16382], "\x7F\xE1\xAE\x01\xFF\x7F\xFE\x7F".b, Bare.ArrayFixedLen(Bare.Uint, 4)],
                   [[:cow, "abc", 123], "\x05\x01\xFE\x7F".b, Bare.ArrayFixedLen(Bare.Enum(testing_hash), 3)],
                   [[:cow, 123, "abc", 123], "\x05\xFE\x7F\x01\xFE\x7F".b, Bare.ArrayFixedLen(Bare.Enum(testing_hash), 4)],
                   [[[1, 2, 3], [4, 5, 6]], "\x01\x02\x03\x04\x05\x06".b, Bare.ArrayFixedLen(Bare.ArrayFixedLen(Bare.U8, 3), 2)], ¬
                 ])
  end

  def test_enum
    testing_hash = { 1 => "abc", 5 => :cow, 16382 => 123 }
    self.enc_dec([
                   [:cow, "\x05".b, Bare.Enum(testing_hash)],
                   ["abc", "\x01".b, Bare.Enum(testing_hash)],
                   [123, "\xFE\x7F".b, Bare.Enum(testing_hash)],
                 ])
  end

  def test_data
    self.enc_dec([
                   ["\xFF\xFF\x00\x00".b, "\x04\xFF\xFF\x00\x00".b, Bare.Data],
                   ["\xFF\xFF\x00\x00\xFF\xFF".b, "\x06\xFF\xFF\x00\x00\xFF\xFF".b, Bare.Data],
                 ])
  end

  def test_data_fixed_len
    self.enc_dec([
                   ["\xFF\xFF\x00\x00".b, "\xFF\xFF\x00\x00".b, Bare.DataFixedLen(4)],
                   ["\xFF\xFF\x00\x00\xFF\xFF".b, "\xFF\xFF\x00\x00\xFF\xFF".b, Bare.DataFixedLen(6)],
                 ])
  end

  def _test_union
    self.enc_dec([
                   [{ type: Bare.Uint, value: 5 }, "\x00\x05".b, Bare.Union({ 0 => Bare.Uint, 1 => Bare.U16 })],
                   [{ type: Bare.U16, value: 5 }, "\x01\x05\x00".b, Bare.Union({ 0 => Bare.Uint, 1 => Bare.U16 })],
                   [{ type: Bare.DataFixedLen(6), value: "\xFF\xFF\x00\x00\xFF\xFF".b }, "\x04\xFF\xFF\x00\x00\xFF\xFF".b, Bare.Union({ 4 => Bare.DataFixedLen(6) })],
                   [{ type: Bare.DataFixedLen(6), value: "\xFF\xFF\x00\x00\xFF\xFF".b }, "\x09\xFF\xFF\x00\x00\xFF\xFF".b, Bare.Union({ 4 => Bare.Uint, 9 => Bare.DataFixedLen(6) })],
                   [{ type: Bare.Uint, value: 5 }, "\x00\x05".b, Bare.Union({ 0 => Bare.Uint, 1 => Bare.Void })],
                 ])
  end

  def test_array_u8
    self.enc_dec([
                   [[3, 5, 6, 7], "\x04\x03\x05\x06\x07".b, Bare.Array(Bare.U8)],
                   [[[1, 2, 3], [4, 5, 6, 8]], "\x02\x03\x01\x02\x03\x04\x04\x05\x06\x08".b, Bare.Array(Bare.Array(Bare.U8))],
                 ])
  end

  def test_struct
    testing_hash = { 1 => "abc", 5 => :cow, 16382 => 123 }
    struct_def = { int: Bare.U8, uint: Bare.Uint, enum: Bare.Enum(testing_hash) }
    struct_def2 = { int: Bare.U8,
                    arr: Bare.ArrayFixedLen(Bare.U8, 3),
                    uint: Bare.Uint,
                    enum: Bare.Enum(testing_hash) }
    self.enc_dec([
                   [{ int: 1, uint: 16382, enum: :cow }, "\x01\xFE\x7F\x05".b, Bare.Struct(struct_def)],
                   [{ enum: :cow, uint: 16382, int: 1 }, "\x01\xFE\x7F\x05".b, Bare.Struct(struct_def)],
                   [{ int: 1, arr: [9, 8, 7], uint: 5, enum: "abc" }, "\x01\x09\x08\x07\x05\x01".b, Bare.Struct(struct_def2)],
                 ])
  end

  def test_map
    testing_hash = { 1 => "abc", 5 => :cow, 16382 => 123 }
    self.enc_dec([
                   [{ 8 => 16, 5 => 10 }, "\x02\x08\x10\x00\x05\x0A\x00".b, Bare.Map(Bare.U8, Bare.U16)],
                   [{ 8 => "abc", 6 => :cow }, "\x02\x08\x01\x06\x05".b, Bare.Map(Bare.U8, Bare.Enum(testing_hash))],
                   [{ preInt: 4, theMap: { 8 => 16, 5 => 10 }, postInt: 5 }, "\x04\x02\x08\x10\x00\x05\x0A\x00\x05".b, Bare.Struct({ preInt: Bare.U8, :theMap => Bare.Map(Bare.U8, Bare.U16), postInt: Bare.U8 })],
                 ])
  end

  def test_optional
    self.enc_dec([
                   [nil, "\x00".b, Bare.Optional(Bare.I8)],
                   [1, "\x01\x01".b, Bare.Optional(Bare.I8)],
                 # [{ preInt: 4, theMap: { 8 => 16, 5 => 10 }, postInt: 5 }, "\01\x04\x02\x08\x10\x00\x05\x0A\x00\x05".b, Bare.Optional(Bare.Struct({ preInt: Bare.U8, :theMap => Bare.Map(Bare.U8, Bare.U16), postInt: Bare.U8 }))],
                 # [{ preInt: 4, opt: nil, postInt: 5 }, "\x04\x00\x05".b, Bare.Struct({ preInt: Bare.U8, :opt => Bare.Optional(Bare.U8), postInt: Bare.U8 })],
                 # [{ preInt: 4, opt: 9, postInt: 5 }, "\x04\x01\x09\x05".b, Bare.Struct({ preInt: Bare.U8, :opt => Bare.Optional(Bare.U8), postInt: Bare.U8 })],
                 ])
  end

  def test_string
    self.enc_dec([
                   ["ABC", "\x03\x41\x42\x43".b, Bare.String],
                   ["A C", "\x03\x41\x20\x43".b, Bare.String],
                   ["😊", "\x04\xF0\x9F\x98\x8A".b, Bare.String],
                   ["😊ABC😊", "\x0B\xF0\x9F\x98\x8A\x41\x42\x43\xF0\x9F\x98\x8A".b, Bare.String],
                   [{ preInt: 4, str: "😊ABC😊", postInt: 5 }, "\x04\x0B\xF0\x9F\x98\x8A\x41\x42\x43\xF0\x9F\x98\x8A\x05".b, Bare.Struct({ preInt: Bare.U8, :str => Bare.String, postInt: Bare.U8 })],
                   [{ preInt: 4, str: " 😊ABC😊 ", postInt: 5 }, "\x04\x0D\x20\xF0\x9F\x98\x8A\x41\x42\x43\xF0\x9F\x98\x8A\x20\x05".b, Bare.Struct({ preInt: Bare.U8, :str => Bare.String, postInt: Bare.U8 })],
                 ])
  end

  def _test_void
    self.enc_dec([
                   [{ type: Bare.Void }, "\x01".b, Bare.Union({ 0 => Bare.Uint, 1 => Bare.Void })],
                 ])
  end

  def test_schema
    testing_hash = {1 => "abc", 5 => :cow, 16382 => 123}
    test_2_enum = {0 => "ACCOUNTING",
                   1 => "ADMINISTRATION",
                   2 => "CUSTOMER_SERVICE",
                   3 => "DEVELOPMENT",
                   99 => "JSMITH" }
    test_3_struct_inner = {
      orderId: Bare.I64,
      quantity: Bare.I32
    }
    test_3_struct = {
      name: Bare.String,
      email: Bare.String,
      orders: Bare.Array(Bare.Struct(test_3_struct_inner)),
      metadata: Bare.Map(Bare.String, Bare.Data)
    }
    test_7 = {PublicKey: Bare.DataFixedLen(128)}
    test_7[:Customer] = Bare.Struct({pubKey: :PublicKey})
    test_8 = {
      PublicKey: Bare.DataFixedLen(128),
      Time: Bare.String,
      Department: Bare.Enum(test_2_enum),
      Customer: Bare.Struct(
        {
          PublicKey: :PublicKey,
          address: :Address,
          name: Bare.String,
          email: Bare.String,
          orders: Bare.Array(Bare.Struct(test_3_struct_inner)),
          metadata: Bare.Map(Bare.String, Bare.Data)
        }),
      Employee: Bare.Struct(
        {
          name: Bare.String,
          email: Bare.String,
          address: :Address,
          department: :Department,
          hireDate: :Time,
          publicKey: Bare.Optional(:PublicKey),
          metadata: Bare.Map(Bare.String, Bare.Data)
        }
      ),
      Person: Bare.Union({0 => :Customer, 1 => :Employee}),
      Address: Bare.Struct({address: Bare.ArrayFixedLen(Bare.String, 4),
                            city: Bare.String,
                            state: Bare.String,
                            country: Bare.String}),
    }

    lexing_tests = [
      {file: "./schemas/test0.schema", ast: {Key: Bare.Array(Bare.Uint)}},
      {file: "./schemas/test1.schema", ast: {Key: Bare.String}},
      {file: "./schemas/test2.schema", ast: {Department: Bare.Enum(test_2_enum)}},
      {file: "./schemas/test3.schema", ast: {Customer: Bare.Struct(test_3_struct)}},
      {file: "./schemas/test4.schema", ast: {Something: Bare.ArrayFixedLen(Bare.String, 5)}},
      {file: "./schemas/test5.schema", ast: {Age: Bare.Optional(Bare.Int)}},
      {file: "./schemas/test6.schema", ast: {A_UNION: Bare.Union({0 => Bare.Int, 1 => Bare.Uint, 7 => Bare.Data, 8 => Bare.F32})}},
      {file: "./schemas/test7.schema", ast: test_7},
      {file: "./schemas/test8.schema", ast: test_8},
    ]


    lexing_tests.each_with_index do |test, i|
      path = rel_path(test[:file])
      schema = Bare.parse_schema(path)
      correct_schema = Bare.Schema(test[:ast])
      assert_equal schema, correct_schema, "Got #{schema} but expected  #{correct_schema} for lexing test #{i+1}"
    end
  end

  def test_schema_e2e
    schema = Bare.parse_schema(rel_path('./schemas/test3.schema'))
    msg = {name: "和製漢字",
           email: "n8 AYT u.northwestern.edu",
           orders: [{orderId: 5, quantity: 11},
                    {orderId: 6, quantity: 2},
                    {orderId: 123, quantity: -5}],
           metadata: {"Something" => "\xFF\xFF\x00\x01".b, "Else" => "\xFF\xFF\x00\x00\xAB\xCC\xAB".b}
    }
    encoded = Bare.encode(msg, schema[:Customer])
    decoded = Bare.decode(encoded, schema[:Customer])
    assert_equal msg, decoded, "Failed end to end schema encoded/decode test"
  end

  def test_odd_schema
    schema = Bare.parse_schema(rel_path("./schemas/test9.schema"))
    input = { A: "\x01\x02\x03".b, B: "\x88".b }
    binary = Bare.encode(input, schema[:TYP])
    decoded = Bare.decode(binary, schema[:TYP])
    assert_equal input, decoded
  end
end