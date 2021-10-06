require 'set'
require_relative "types"
require_relative "lexer"
require_relative "parser"
require_relative 'dfs'

class Bare
  def self.encode(msg, schema, type = nil)
    buffer = "".b
    if schema.is_a?(Bare::Schema)
      raise NoTypeProvided("To encode with a schema as opposed to a raw type you must specify which type in the schema you want to encode as a symbol.\nBare.encode(msg, schema, :Type)") if type.nil?
      unless schema.include?(type)
        raise("#{typ} is not a type found in this schema. Choose from #{schema.types.keys}")
      end
      schema[type].encode(msg, buffer)
    else
      schema.encode(msg, buffer)
    end
    buffer
  end

  def self.decode(msg, schema, type = nil)
    if schema.is_a?(Bare::Schema)
      raise NoTypeProvided("To decode with a schema as opposed to a raw type you must specify which type in the same you want to encode as a symbol.\nBare.encode(msg, schema, :Type)") if type.nil?
      value, _ = schema[type].decode(msg)
      value
    else
      value, _ = schema.decode(msg)
      value
    end
  end

  def self.parse_schema(path)
    # Hash of class names to BARE types
    # Eg. types['Customer'] == Bare.i32
    parsed = parser(lexer(path))
    Bare.Schema(parsed)
  end

  def self.Schema(hash)
    Bare::Schema.new(hash)
  end

  class Schema
    attr_accessor :types

    def initialize(types)
      @types = types.map { |k, v| [k.to_sym, v] }.to_h
      @types.each do |k, v|
        unless k.is_a?(Symbol)
          raise("Keys to a schema must be symbols")
        end
        if v.nil?
          raise("Schema values cannot be nil")
        end
      end

      # Resolve references in schema
      # type A u8
      # type B A
      # type C B
      # first  loop would find B and make it a reference to A
      # second loop would find C and make it a reference to B
      progress = true
      remaining = @types.keys.to_a
      while progress
        progress = false
        remaining.each do |key|
          val = @types[key]
          if val.is_a?(Symbol) && !@types[val].is_a?(Symbol)
            @types[key.to_sym] = BareTypes::Reference.new(key, @types[val])
            progress = true
          else
          end
        end
      end

      @types.each do |key, val|
        if val.is_a?(Symbol)
          raise ReferenceException.new("Your types contain an unresolved reference '#{val}'.")
        end
      end

      @types.values.each do |val|
        val.finalize_references(@types)
      end

      @types.each do |key, val|
        val.cycle_search(SeenList.new)
      end
    end

    def ==(otherSchema)
      return false unless otherSchema.is_a?(Bare::Schema)
      @types == otherSchema.types
    end

    def to_s
      buffer = ""
      @types.each do |name, type|
        if type.is_a?(BareTypes::Enum)
          buffer << "enum #{name} "
          type.to_schema(buffer)
          buffer << "\n"
        else
          buffer << "type #{name} "
          type.to_schema(buffer)
          buffer << "\n"
        end
      end
      buffer
    end

    def [](key)
      return @types[key]
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
