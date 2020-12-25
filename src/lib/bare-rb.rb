require 'set'
require_relative "types"
require_relative "lexer"
require_relative "parser"

class Bare

  def self.parse_schema(path)
    # Hash of class names to BARE ASTs
    # Eg. types['Customer'] == Bare.i32
    types = parser(lexer(path))
    return types
  end

  def self.encode(msg, schema)
    return schema.encode(msg)
  end

  def self.decode(msg, schema)
    return schema.decode(msg)[:value]
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

