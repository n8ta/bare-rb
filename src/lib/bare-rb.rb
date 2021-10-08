require 'set'
require_relative "types"
require_relative "lexer"
require_relative "parser"
require_relative 'dfs'
require_relative 'generative_testing/gen'
require_relative 'generative_testing/monkey_patch'

class Bare
  def self.encode(msg, schema, type = nil)
    buffer = "".b
    if schema.is_a?(BareTypes::Schema)
      raise NoTypeProvided.new("To encode with a schema as opposed to a raw type you must specify which type in the schema you want to encode as a symbol.\nBare.encode(msg, schema, :Type)") if type.nil?
      unless schema.types.include?(type)
        raise("#{type} is not a type found in this schema. Choose from #{schema.types.keys}")
      end
      schema[type].encode(msg, buffer)
    else
      schema.encode(msg, buffer)
    end
    buffer
  end

  def self.decode(msg, schema, type = nil)
    if schema.is_a?(BareTypes::Schema)
      raise NoTypeProvided.new("To decode with a schema as opposed to a raw type you must specify which type in the same you want to encode as a symbol.\nBare.encode(msg, schema, :Type)") if type.nil?
      value, _ = schema[type].decode(msg)
      value
    else
      value, _ = schema.decode(msg)
      value
    end
  end

  # Returns a schema and a binary input
  # optionally write these to files
  def self.generative_test(schema_path=nil, binary_path=nil)
    schema = BareTypes::Schema.make
    input = schema.create_input
    key = schema.types.keys[0]
    binary = Bare.encode(input[key], schema, key)
    unless binary_path.nil?
      file = File.open(binary_path, 'wb+')
      file.write(binary)
      file.close
    end
    unless schema_path.nil?
      file = File.open(schema_path, 'w+')
      file.write(schema.to_s)
      file.close
    end
    return schema, binary, key
  end

  def self.parse_schema(path)
    # Hash of class names to BARE types
    # Eg. types['Customer'] == Bare.i32
    parsed = parser(lexer(path))
    Bare.Schema(parsed)
  end

  def self.Schema(hash)
    BareTypes::Schema.new(hash)
  end

  # These classes are wrapped in methods for ergonomics.
  # Isn't Bare.Array(Bare.U8) nicer than Bare::Array.new(Bare::U8.new)?

  def self.Int
    return BareTypes::Int.new
  end

  def self.Void
    return BareTypes::Void.new
  end

  def self.F32
    return BareTypes::F32.new
  end

  def self.F64
    return BareTypes::F64.new
  end

  def self.String
    return BareTypes::String.new
  end

  def self.U8
    return BareTypes::U8.new
  end

  def self.U16
    return BareTypes::U16.new
  end

  def self.U32
    return BareTypes::U32.new
  end

  def self.U64
    return BareTypes::U64.new
  end

  def self.I8
    return BareTypes::I8.new
  end

  def self.I16
    return BareTypes::I16.new
  end

  def self.I32
    return BareTypes::I32.new
  end

  def self.I64
    return BareTypes::I64.new
  end

  def self.Optional(*opts)
    return BareTypes::Optional.new(*opts)
  end

  def self.Map(*opts)
    return BareTypes::Map.new(*opts)
  end

  def self.Union(*opts)
    return BareTypes::Union.new(*opts)
  end

  def self.DataFixedLen(*opts)
    return BareTypes::DataFixedLen.new(*opts)
  end

  def self.Data
    return BareTypes::Data.new
  end

  def self.Uint
    return BareTypes::Uint.new
  end

  def self.Bool
    return BareTypes::Bool.new
  end

  def self.Struct(*opts)
    return BareTypes::Struct.new(*opts)
  end

  def self.Array(*opts)
    return BareTypes::Array.new(*opts)
  end

  def self.ArrayFixedLen(*opts)
    return BareTypes::ArrayFixedLen.new(*opts)
  end

  def self.Enum(*opts)
    return BareTypes::Enum.new(*opts)
  end
end
