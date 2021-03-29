require 'set'
require_relative "types"
require_relative "lexer"
require_relative "parser"

class Bare
  def self.encode(msg, schema, type=nil)
    if schema.is_a?(Bare::Schema)
      raise NoTypeProvided("To encode with a schema as opposed to a raw type you must specify which type in the schema you want to encode as a symbol.\nBare.encode(msg, schema, :Type)") if type.nil?
      schema[type].encode(msg)
    else
      schema.encode(msg)
    end
  end

  def self.decode(msg, schema, type=nil)
    if schema.is_a?(Bare::Schema)
      raise NoTypeProvided("To decode with a schema as opposed to a raw type you must specify which type in the same you want to encode as a symbol.\nBare.encode(msg, schema, :Type)") if type.nil?
      value, rest = schema[type].decode(msg)
      value
    else
      value, rest = schema.decode(msg)
      return value
    end
  end

  def self.parse_schema(path)
    # Hash of class names to BARE ASTs
    # Eg. types['Customer'] == Bare.i32
    types = parser(lexer(path))
    Bare.Schema(types)
  end

  def self.Schema(hash)
    Bare::Schema.new(hash)
  end

  class Schema
    def ==(otherSchema)
      return false unless otherSchema.is_a?(Bare::Schema)
      @types == otherSchema.types
    end

    def types
      @types
    end

    def [](key)
      return @types[key]
    end

    def initialize(types)
      @types = types
      @types.keys.each do |key|
        if @types[key].is_a?(Symbol)
          @types[key] = @types[@types[key]]
        else
          # Users may use symbols to reference not yet defined types
          # here we recursively call our bare classes to finalize their types
          # replacing Symbols like :SomeType with a reference to the other type
          @types[key].finalize_references(@types)
        end
      end
    end
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

