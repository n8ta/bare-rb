require_relative './exceptions'

class BareTypes

  class BaseType
    def initialize
      @finalized = false
      super
    end
  end

  # Used to represent a Type reference in a schema.
  # eg. test8.schema's  address field on Customer contains 'Address'
  # a reference to the Address type defined earlier.
  class Reference < BaseType
    attr_accessor :name
    attr_accessor :ref

    def ==(other)
      other.is_a?(Reference) && @name == other.name && @ref == other.ref
    end

    def initialize(name, reference)
      @name = name
      @ref = reference
      @finalized = false
      unless reference.is_a?(BareTypes::BaseType)
        raise ReferenceException.new("Reference must be to bare types")
      end
    end

    def finalize_references(schema)
      return if @finalized
      @finalized = true
      self.ref.finalize_references(schema)
    end

    def encode(msg, buffer)
      @ref.encode(msg, buffer)
    end

    def decode(msg)
      @ref.decode(msg)
    end

    def to_schema(buffer)
      @ref.to_schema(buffer)
    end

  end

  class BarePrimitive < BaseType

    # Types which are always equivalent to another instantiation of themselves
    # Eg. Uint.new == Uint.new
    # But Union.new(types1) != Union.new(types2)
    #   since unions could have different sets of types

    def ==(other)
      self.class == other.class
    end

    def finalize_references(schema) end

    def to_schema(buffer)
      buffer << self.class.name.split('::').last.downcase
    end

  end

  class Int < BarePrimitive
    # https://developers.google.com/protocol-buffers/docs/encoding
    # Easy to just convert to signed and re-use uint code
    def encode(msg, buffer)
      mappedInteger = msg < 0 ? -2 * msg - 1 : msg * 2
      Uint.new.encode(mappedInteger, buffer)
    end

    def decode(msg)
      value, rest = Uint.new.decode(msg)
      value = value.odd? ? (value + 1) / -2 : value / 2
      return value, rest
    end
  end

  class Void < BarePrimitive
    def encode(msg, buffer)
      buffer << "".b
    end

    def decode(msg)
      return nil, msg
    end
  end

  class F32 < BarePrimitive
    def encode(msg, buffer)
      buffer << [msg].pack("e")
    end

    def decode(msg)
      return msg.unpack("e")[0], msg[4..msg.size]
    end
  end

  class F64 < BarePrimitive
    def encode(msg, buffer)
      buffer << [msg].pack("E")
    end

    def decode(msg)
      return msg.unpack("E")[0], msg[8..msg.size]
    end
  end

  class String < BarePrimitive
    def encode(msg, buffer)
      begin
        encodedString = msg.encode("UTF-8").b
      rescue Encoding::UndefinedConversionError => error
        raise error.class, "Unable to convert string to UTF-8=, BARE strings are encoded as UTF8. If you can't convert your string to UTF-8 you can encode it with binary data"
      end
      Uint.new.encode(encodedString.size, buffer)
      buffer << encodedString
    end

    def decode(msg)
      strLen, rest = Uint.new.decode(msg)
      string = rest[0..strLen - 1]
      return string.force_encoding("utf-8"), rest[strLen..rest.size]
    end
  end

  class Optional < BaseType
    def ==(otherType)
      return otherType.class == BareTypes::Optional && otherType.optionalType == @optionalType
    end

    def to_schema(buffer)
      buffer << "optional<"
      @optionalType.to_schema(buffer)
      buffer << ">"
    end

    def finalize_references(schema)
      return if @finalized
      @finalized = true
      if @optionalType.is_a?(Symbol)
        @optionalType = Reference.new(@optionalType, schema[@optionalType])
      else
        @optionalType.finalize_references(schema)
      end
    end

    def optionalType
      @optionalType
    end

    def initialize(optionalType)
      raise VoidUsedOutsideTaggedSet() if optionalType.class == BareTypes::Void
      @optionalType = optionalType
    end

    def encode(msg, buffer)
      if msg.nil?
        buffer << "\x00".b
      else
        buffer << "\x01".b
        @optionalType.encode(msg, buffer)
      end
    end

    def decode(msg)
      if msg.unpack("C")[0] == 0
        return nil, msg[1..msg.size]
      else
        return @optionalType.decode(msg[1..msg.size])
      end
    end
  end

  class Map < BaseType
    def ==(otherType)
      return otherType.class == BareTypes::Map && otherType.from == @from && otherType.to == @to
    end

    def to_schema(buffer)
      buffer << "map["
      @from.to_schema(buffer)
      buffer << "]"
      @to.to_schema(buffer)
    end

    def finalize_references(schema)
      return if @finalized
      @finalized = true
      if @from.is_a?(Symbol)
        @to = Reference.new(@from, schema[@to])
      else
        @to.finalize_references(schema)
      end
    end

    def initialize(fromType, toType)
      raise VoidUsedOutsideTaggedSet if fromType.class == BareTypes::Void or toType.class == BareTypes::Void
      if !fromType.class.ancestors.include?(BarePrimitive) ||
        fromType.is_a?(BareTypes::Data) ||
        fromType.is_a?(BareTypes::DataFixedLen)
        raise MapKeyError("Map keys must use a primitive type which is not data or data<length>.")
      end
      @from = fromType
      @to = toType
    end

    def from
      @from
    end

    def to
      @to
    end

    def encode(msg, buffer)
      Uint.new.encode(msg.size, buffer)
      msg.each do |from, to|
        @from.encode(from, buffer)
        @to.encode(to, buffer)
      end
    end

    def decode(msg)
      hash = Hash.new
      mapSize, rest = Uint.new.decode(msg)
      # (0..mapSize).each do
      (mapSize - 1).to_i.downto(0) do
        key, rest = @from.decode(rest)
        value, rest = @to.decode(rest)
        hash[key] = value
      end
      return hash, rest
    end
  end

  class Union < BaseType
    attr_accessor :intToType

    def finalize_references(schema)
      return if @finalized
      @finalized = true
      @intToType.keys.each do |key|
        if @intToType[key].is_a?(Symbol)
          @intToType[key] = Reference.new(@intToType[key], schema[@intToType[key]])
        else
          @intToType[key].finalize_references(schema)
        end
      end
    end

    def ==(otherType)
      return false unless otherType.is_a?(BareTypes::Union)
      @intToType.each do |int, type|
        return false unless type == otherType.intToType[int]
      end
      true
    end

    def initialize(intToType)
      intToType.keys.each do |i|
        raise MinimumSizeError("Union's integer representations must be > 0, instead got: #{i}") if i < 0 or !i.is_a?(Integer)
      end
      raise MinimumSizeError("Union must have at least one type") if intToType.keys.size < 1
      @intToType = intToType
    end

    def to_schema(buffer)
      buffer << "("
      strs = []
      @intToType.size.times do
        strs << ""
      end
      @intToType.values.each_with_index.map { |type, i| type.to_schema(strs[i]) }
      buffer << strs.join(" | ")
      buffer << ")"
    end

    def encode(msg, buffer)
      type = msg[:type]
      value = msg[:value]
      unionTypeInt = nil
      unionType = nil
      @intToType.each do |int, typ|
        if type.class == typ.class
          unionTypeInt = int
          unionType = typ
          break
        end
      end
      raise SchemaMismatch("Unable to find given type in union: #{@intToType.inspect}, type: #{type}") if unionType.nil? || unionTypeInt.nil?
      Uint.new.encode(unionTypeInt, buffer)
      unionType.encode(value, buffer)
    end

    def decode(msg)
      int, rest = Uint.new.decode(msg)
      type = @intToType[int]
      value, rest = type.decode(rest)
      return { value: value, type: type }, rest
    end
  end

  class DataFixedLen < BaseType
    def ==(otherType)
      return otherType.class == BareTypes::DataFixedLen && otherType.length == self.length
    end

    def to_schema(buffer)
      buffer << "data<#{@length}>"
    end

    def length
      @length
    end

    def finalize_references(schema) end

    def initialize(length)
      raise MinimumSizeError.new("DataFixedLen must have a length greater than 0, got: #{length.inspect}") if length < 1
      @length = length
    end

    def encode(msg, buffer)
      if msg.size != @length
        raise FixedDataSizeWrong.new("Message is not proper sized for DataFixedLen should have been #{@length} but was #{msg.size}")
      end
      buffer << msg
    end

    def decode(msg)
      return msg[0..@length-1], msg[@length..msg.size]
    end
  end

  class Data < BarePrimitive

    def finalize_references(schema) end

    def encode(msg, buffer)
      Uint.new.encode(msg.size, buffer)
      buffer << msg
    end

    def decode(msg)
      dataSize, rest = Uint.new.decode(msg)
      return rest[0..dataSize - 1], rest[dataSize..rest.size]
    end
  end

  class Uint < BarePrimitive

    def finalize_references(schema) end

    def encode(msg, buffer)
      bytes = "".b
      _get_next_7_bits_as_byte(msg, 128) do |byte|
        bytes << byte
      end
      (bytes.size - 1).downto(0) do |i|
        if bytes.bytes[i] == 128 && bytes.size > 1
          bytes = bytes.chop
        else
          break
        end
      end
      bytes[bytes.size - 1] = [bytes.bytes[bytes.size - 1] & 127].pack('C')[0]
      raise MaximumSizeError.new("Maximum u/int allowed is 64 bit precision") if bytes.size > 9
      buffer << bytes
    end

    def decode(msg)
      ints = msg.unpack("CCCCCCCC")
      relevantInts = []
      i = 0
      while ints[i] & 0b10000000 == 128
        relevantInts << ints[i] % 128
        i += 1
      end
      relevantInts << ints[i]
      sum = 0
      relevantInts.each_with_index do |int, idx|
        sum += int << (idx * 7)
      end
      return sum, msg[(i + 1)..msg.size]
    end
  end

  class U8 < BarePrimitive
    def encode(msg, buffer)
      buffer << [msg].pack("C")
    end

    def decode(msg)
      return msg[0].unpack("C")[0], msg[1..msg.size]
    end
  end

  class U16 < BarePrimitive
    def encode(msg, buffer)
      buffer << [msg].pack("v")
    end

    def decode(msg)
      return msg.unpack("v")[0], msg[2..msg.size]
    end
  end

  class U32 < BarePrimitive
    def encode(msg, buffer)
      buffer << [msg].pack("V")
    end

    def decode(msg)
      return msg.unpack("V")[0], msg[4..msg.size]
    end
  end

  class U64 < BarePrimitive
    def encode(msg, buffer)
      buffer << [msg].pack("Q")
    end

    def decode(msg)
      return msg.unpack("Q")[0], msg[8..msg.size]
    end
  end

  class I8 < BarePrimitive
    def encode(msg, buffer)
      buffer << [msg].pack("c")
    end

    def decode(msg)
      return msg[0].unpack("c")[0], msg[1..msg.size]
    end
  end

  class I16 < BarePrimitive
    def encode(msg, buffer)
      buffer << [msg].pack("s<")
    end

    def decode(msg)
      return msg.unpack('s<')[0], msg[2..msg.size]
    end
  end

  class I32 < BarePrimitive
    def encode(msg, buffer)
      buffer << [msg].pack("l<")
    end

    def decode(msg)
      return msg.unpack('l<')[0], msg[4..msg.size]
    end
  end

  class I64 < BarePrimitive
    def encode(msg, buffer)
      buffer << [msg].pack("q<")
    end

    def decode(msg)
      return msg.unpack('q<')[0], msg[8..msg.size]
    end
  end

  class Bool < BarePrimitive
    def encode(msg, buffer)
      buffer << (msg ? "\x00".b : "\x01".b)
    end

    def decode(msg)
      if msg != "\x00" && msg != "\x01"
        raise InvalidBool.new("Expected a bool but found #{msg.inspect}. Standard requires bool to be 0x00 or 0x01")
      end
      return (msg == "\x00" ? true : false), msg[1..msg.size]
    end
  end

  class Struct < BaseType
    attr_accessor :mapping

    def [](key)
      @mapping[key]
    end

    def ==(otherType)
      return false unless otherType.class == BareTypes::Struct
      @mapping.each do |k, v|
        return false unless otherType.mapping[k] == v
      end
      true
    end

    def finalize_references(schema)
      return if @finalized
      @finalized = true
      @mapping.each do |key, val|
        if val.is_a?(Symbol)
          @mapping[key] = Reference.new(val, schema[val])
          begin
            @mapping[key].ref.finalize_references(schema)
          rescue NoMethodError => e
            puts "err"
          end
        else
          val.finalize_references(schema)
        end
      end
    end

    def initialize(symbolToType)
      # Mapping from symbols to Bare types (or possibly symbols before finalizing)
      symbolToType.keys.each do |k|
        raise BareException.new("Struct keys must be symbols") unless k.is_a?(Symbol)
        if (!symbolToType[k].class.ancestors.include?(BaseType) && !symbolToType[k].is_a?(Symbol))
          raise BareException.new("Struct values must be a BareTypes::TYPE or a symbol with the same
                name as a user defined type\nInstead got: #{symbolToType[k].inspect}")
        end
        raise VoidUsedOutsideTaggedSet.new("Void types may only be used as members of the set of types in a tagged union. Void type used as struct key") if symbolToType.class == BareTypes::Void
      end
      raise("Struct must have at least one field") if symbolToType.keys.size == 0
      @mapping = symbolToType
    end

    def encode(msg, buffer)
      @mapping.keys.each do |symbol|
        raise SchemaMismatch.new("All struct fields must be specified, missing: #{symbol.inspect}") unless msg.keys.include?(symbol)
        @mapping[symbol].encode(msg[symbol], buffer)
      end
    end

    def decode(msg)
      hash = Hash.new
      rest = msg
      @mapping.keys.each do |symbol|
        value, rest = @mapping[symbol].decode(rest)
        hash[symbol] = value
      end
      return hash, rest
    end

    def to_schema(buffer)
      buffer << "{"
      @mapping.each do |symbol, type|
        buffer << "    #{symbol}: "
        type.to_schema(buffer)
        buffer << "\n"
      end
      buffer << "}"
    end

  end

  class Array < BaseType
    def ==(otherType)
      otherType.class == BareTypes::Array && otherType.type == self.type
    end

    def type
      @type
    end

    def to_schema(buffer)
      buffer << "[]"
      @type.to_schema(buffer)
    end

    def finalize_references(schema)
      return if @finalized
      @finalized = true
      if @type.is_a?(Symbol)
        @type = Reference.new(@type, schema[@type])
      else
        @type.finalize_references(schema)
      end
    end

    def initialize(type)
      raise VoidUsedOutsideTaggedSet.new("Void types may only be used as members of the set of types in a tagged union.") if type.class == BareTypes::Void
      @type = type
    end

    def encode(msg, buffer)
      Uint.new.encode(msg.size, buffer)
      msg.each do |item|
        @type.encode(item, buffer)
      end
    end

    def decode(msg)
      arr = []
      arrayLen, rest = Uint.new.decode(msg)
      lastSize = msg.size + 1 # Make sure msg size monotonically decreasing
      (arrayLen - 1).downto(0) do
        arrVal, rest = @type.decode(rest)
        arr << arrVal
        break if rest.nil? || rest.size == 0 || lastSize <= rest.size
        lastSize = rest.size
      end
      return arr, rest
    end
  end

  class ArrayFixedLen < BaseType
    attr_accessor :type, :size

    def ==(otherType)
      return otherType.class == BareTypes::ArrayFixedLen && otherType.type == @type && otherType.size == @size
    end

    def finalize_references(schema)
      return if @finalized
      @finalized = true
      if @type.is_a?(Symbol)
        @type = Reference.new(@type, schema[@type])
      else
        @type.finalize_references(schema)
      end
    end

    def initialize(type, size)
      @type = type
      @size = size
      raise VoidUsedOutsideTaggedSet.new("Void type may not be used as type of fixed length array.") if type.class == BareTypes::Void
      raise MinimumSizeError.new("ArrayFixedLen size must be > 0") if size < 1
    end

    def encode(arr, buffer)
      raise SchemaMismatch.new("This ArrayFixedLen is of length #{@size.to_s} but you passed an array of length #{arr.size}") if arr.size != @size
      arr.each do |item|
        @type.encode(item, buffer)
      end
    end

    def decode(rest)
      array = []
      @size.times do
        arrVal, rest = @type.decode(rest)
        array << arrVal
      end
      return array, rest
    end

    def to_schema(buffer)
      buffer << "[#{@size}]"
      @type.to_schema(buffer)
    end
  end

  class Enum < BaseType
    def ==(otherType)
      return false unless otherType.class == BareTypes::Enum
      @intToVal.each do |int, val|
        return false unless otherType.intToVal[int] == val
      end
      return true
    end

    def to_schema(buffer)
      buffer << "{\n"
      @valToInt.each do |name, repr|
        buffer << "   #{name} = #{repr}\n"
      end
      buffer << "}"
    end

    def finalize_references(schema) end

    def intToVal
      @intToVal
    end

    def initialize(source)
      @intToVal = {}
      @valToInt = {}
      raise BareException.new("Enum must initialized with a hash from integers to anything") if !source.is_a?(Hash)
      raise BareException.new("Enum must have unique positive integer assignments") if Set.new(source.keys).size != source.keys.size
      raise EnumValueError.new("Enum must have unique values") if source.values.to_set.size != source.values.size
      source.each do |k, v|
        raise("Enum keys must be positive integers") if k < 0
        @intToVal[k.to_i] = v
        @valToInt[v] = k.to_i
      end
    end

    def encode(msg, buffer)
      raise SchemaMismatch.new("#{msg.inspect} is not part of this enum: #{@intToVal}") if !@valToInt.keys.include?(msg)
      integerRep = @valToInt[msg]
      BareTypes::Uint.new.encode(integerRep, buffer)
    end

    def decode(msg)
      value, rest = BareTypes::Uint.new.decode(msg)
      return @intToVal[value], rest
    end
  end

end

def _get_next_7_bits_as_byte(integer, base = 128)
  # Base is the initial value of the byte before
  # before |'ing it with 7bits from the integer
  groups_of_7 = (integer.size * 8) / 7 + (integer.size % 7 == 0 ? 0 : 1)
  0.upto(groups_of_7 - 1) do |group_number|
    byte = base
    0.upto(7).each do |bit_number|
      byte = byte | (integer[group_number * 7 + bit_number] << bit_number)
    end
    yield(byte)
  end
end
