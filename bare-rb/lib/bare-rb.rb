require 'set'


class Bare
  def self.encode(msg, schema)
    return schema.encode(msg)
  end

  def self.decode(msg, schema)
    return schema.decode(msg)[:value]
  end

  class BareType
  end
  class Primitive < BareType
    # Types which are always equivalent to another instantiation of themselves
    # Eg. Uint.new == Uint.new
    # But Union.new(types1) != Union.new(types2)
    #   since unions can hold differnet values
    def ==(other)
      self.class == other.class
    end
  end


  class Map < BareType
    def initialize(fromType, toType)
      raise("Map keys must use a primitive type which is not data or data<length>.") if
          !fromType.class.ancestors.include?(Primitive) || fromType.is_a?(Bare::Data) || fromType.is_a?(Bare::DataFixedLen)
      @from = fromType
      @to = toType
    end
    def encode(msg)
      bytes = Uint.new.encode(msg.size)
      msg.each do |from, to|
        bytes << @from.encode(from)
        bytes << @to.encode(to)
      end
      return bytes
    end
    def decode(msg)
      hash = Hash.new
      output = Uint.new.decode(msg)
      mapSize = output[:value]
      (mapSize-1).to_i.downto(0) do
        output = @from.decode(output[:rest])
        key = output[:value]
        output = @to.decode(output[:rest])
        hash[key] = output[:value]
        hash[key] = output[:value]
      end
      return {value: hash, rest: output[:rest]}
    end
  end



  class Union < Primitive
    def intToType
      @intToType
    end

    def ==(otherType)
      return false unless otherType.is_a?(Bare::Union)
      @intToType.each do |int, type|
        return false unless type == otherType.intToType[int]
      end
      return true
    end

    def initialize(intToType)
      intToType.keys.each do |i|
        raise("Unions integer representations must be > 0") if i < 0 or !i.is_a?(Integer)
      end
      raise("Union must have at least one type") if intToType.keys.size < 1
      @intToType = intToType
    end

    def encode(msg)
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
      raise("Unable to find matching type in union") if unionType.nil? || unionTypeInt.nil?
      bytes = Uint.new.encode(unionTypeInt)
      encoded = unionType.encode(value)
      bytes << encoded
    end

    def decode(msg)
      unionTypeInt = Uint.new.decode(msg)
      int = unionTypeInt[:value]
      type = @intToType[int]
      value = type.decode(unionTypeInt[:rest])
      return {value: {value: value[:value], type: type}, rest: value[:rest]}
    end
  end

  class DataFixedLen < BareType
    def ==(otherType)
      return otherType.class == Bare::DataFixedLen && otherType.length == self.length
    end

    def length
      return @length
    end

    def initialize(length)
      raise("DataFixedLen must have a length greater than 0") if length < 1
      @length = length
    end

    def encode(msg)
      return msg
    end

    def decode(msg)
      return {value: msg[0..@length], rest: msg[@length..msg.size]}
    end
  end

  class Data < Primitive
    def encode(msg)
      bytes = Uint.new.encode(msg.size)
      bytes << msg
      return bytes
    end

    def decode(msg)
      output = Uint.new.decode(msg)
      rest = output[:rest]
      dataSize = output[:value]
      return {value: rest[0..dataSize], rest: rest[dataSize..rest.size]}
    end
  end

  class Uint < Primitive
    def ==(otherObject)
      otherObject.class == Uint
    end

    def encode(msg)
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
      raise("Maximum u/int allowed is 64 bit precision") if bytes.size > 9
      return bytes
    end

    def decode(msg)
      ints = msg.unpack("CCCCCCCCC")
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
      return {value: sum, rest: msg[(i + 1)..msg.size]}
    end
  end

  class U8 < Primitive
    def encode(msg)
      return [msg].pack("C")
    end

    def decode(msg)
      return {value: msg[0].unpack("C")[0], rest: msg[1..msg.size]}
    end
  end

  class U16 < Primitive
    def encode(msg)
      return [msg].pack("v")
    end

    def decode(msg)
      return {value: msg.unpack("v")[0], rest: msg[2..msg.size]}
    end
  end

  class U32 < Primitive
    def encode(msg)
      return [msg].pack("V")
    end

    def decode(msg)
      return {value: msg.unpack("V")[0], rest: msg[4..msg.size]}
    end
  end

  class U64 < Primitive
    def encode(msg)
      return [msg].pack("Q")
    end

    def decode(msg)
      return {value: msg.unpack("Q")[0], rest: [8..msg.size]}
    end
  end

  class I8 < Primitive
    def encode(msg)
      return [msg].pack("c")
    end

    def decode(msg)
      return {value: msg[0].unpack("c")[0], rest: msg[1..msg.size]}
    end
  end

  class I16 < Primitive
    def encode(msg)
      return [msg].pack("s<")
    end

    def decode(msg)
      return {value: msg.unpack('s<')[0], rest: msg[2..msg.size]}
    end
  end

  class I32 < Primitive
    def encode(msg)
      return [msg].pack("l<")
    end

    def decode(msg)
      return {value: msg.unpack('l<')[0], rest: msg[4..msg.size]}
    end
  end

  class I64 < Primitive
    def encode(msg)
      return [msg].pack("q<")
    end

    def decode(msg)
      return {value: msg.unpack('q<')[0], rest: msg[8..msg.size]}
    end
  end

  class Bool < Primitive
    def encode(msg)
      return msg ? "\xFF\xFF".b : "\x00\x00".b
    end

    def decode(msg)
      return {value: msg == "\x00\x00" ? false : true, rest: msg[1..msg.size]}
    end
  end

  class Struct < BareType
    def initialize(symbolToType)
      # Mapping from symbols to Bare types
      symbolToType.keys.each do |k|
        raise("Struct keys must be symbols") unless k.is_a?(Symbol)
        raise("Struct values must be a Bare::TYPE\nInstead got: #{symbolToType[k].inspect}") unless symbolToType[k].class.ancestors.include?(BareType)
      end
      raise("Struct must have at least one field") if symbolToType.keys.size == 0
      @mapping = symbolToType
    end

    def encode(msg)
      bytes = "".b
      @mapping.keys.each do |symbol|
        raise("All struct fields must be specified, missing: #{symbol.inspect}") unless msg.keys.include?(symbol)
        bytes << @mapping[symbol].encode(msg[symbol])
      end
      return bytes
    end

    def decode(msg)
      hash = Hash.new
      rest = msg
      @mapping.keys.each do |symbol|
        output = @mapping[symbol].decode(rest)
        hash[symbol] = output[:value]
        rest = output[:rest]
      end
      return {value: hash, rest: rest}
    end
  end

  class Array < BareType
    def ==(otherType)
      return otherType.class == Bare::Array && otherType.type == self.type
    end

    def type
      return @type
    end

    def initialize(type)
      @type = type
    end

    def encode(msg)
      bytes = Uint.new.encode(msg.size)
      msg.each do |item|
        bytes << @type.encode(item)
      end
      return bytes
    end

    def decode(msg)
      output = Uint.new.decode(msg)
      arr = []
      arrayLen = output[:value]
      lastSize = msg.size + 1 # Make sure msg size monotonically decreasing
      (arrayLen - 1).downto(0) do
        output = @type.decode(output[:rest])
        arr << output[:value]
        break if output[:rest].nil? || output[:rest].size == 0 || lastSize <= output[:rest].size
        lastSize = output[:rest].size
      end
      return {value: arr, rest: output[:rest]}
    end
  end

  class ArrayFixedLen < BareType
    def initialize(type, size)
      @type = type
      @size = size
      raise("FixedLenArray size must be > 0") if size < 1
    end

    def encode(arr)
      raise("This FixLenArray is of length #{@size.to_s} but you passed an array of length #{arr.size}") if arr.size != @size
      bytes = ""
      arr.each do |item|
        bytes << @type.encode(item)
      end
      return bytes
    end

    def decode(msg)
      array = []
      rest = msg
      @size.times do
        output = @type.decode(rest)
        rest = output[:rest]
        array << output[:value]
      end
      return {value: array, rest: rest}
    end
  end

  class Enum < BareType
    def initialize(source)
      @intToVal = {}
      @valToInt = {}
      raise("Enum sources must be hash from integers to anything") if !source.is_a?(Hash)
      raise("Enum must have unique positive integer assignments") if Set.new(source.keys).size != source.keys.size
      raise("Enum must have unique values") if source.values.to_set.size != source.values.size
      source.each do |k, v|
        raise("Enum keys must be positive integers") if k < 0
        @intToVal[k.to_i] = v
        @valToInt[v] = k.to_i
      end
    end

    def encode(msg)
      raise("#{msg.inspect} is not part of your enum") if !@valToInt.keys.include?(msg)
      integerRep = @valToInt[msg]
      encoded = Bare::Uint.new.encode(integerRep)
      return encoded
    end

    def decode(msg)
      output = Bare::Uint.new.decode(msg)
      value = output[:value]
      rest = output[:rest]
      return {value: @intToVal[value], rest: rest}
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
