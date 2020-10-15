class Bare
  def self.encode(msg, schema)
    case schema
    when Bare::DataTypes::U8
      return [msg].pack("C")
    when Bare::DataTypes::U16
      return [msg].pack("v")
    when Bare::DataTypes::U32
      return [msg].pack("V")
    when Bare::DataTypes::U64
      return [msg].pack("Q")
    when Bare::DataTypes::I8
      return [msg].pack("c")
    when Bare::DataTypes::I16
      return [msg].pack("s<")
    when Bare::DataTypes::I32
      return [msg].pack("l<")
    when Bare::DataTypes::I64
      return [msg].pack("q<")
    when Bare::DataTypes::Bool
      return msg ? "\xFF\xFF".b : "\x00\x00".b
    when Bare::DataTypes::Uint
      bytes = "".b
      get_next_7_bits_as_byte(msg, 128) do |byte|
        bytes << byte
      end
      (bytes.size - 1).downto(0) do |i|
        if bytes.bytes[i] == 128
          bytes = bytes.chop
        else
          break
        end
      end
      bytes[bytes.size - 1] = [bytes.bytes[bytes.size - 1] & 127].pack('C')[0]
      return bytes
    else
      raise("Unknown type: #{schema.inspect}. make sure you call .new on Bare::DataType::XYZ!")
    end
  end

  def self.decode(msg, schema)
    result = self._parser(msg, schema)
    return result[:value]
  end

  def self._parser(msg, schema, rest=nil)
    case schema
    when Bare::DataTypes::U8
      return {value: msg[0].unpack("C")[0], rest: nil}
    when Bare::DataTypes::U16
      return {value: msg.unpack("v")[0], rest: nil}
    when Bare::DataTypes::U32
      return {value: msg.unpack("V")[0], rest: nil}
    when Bare::DataTypes::U64
      return {value: msg.unpack("Q")[0], rest: nil}
    when Bare::DataTypes::I8
      return {value: msg[0].unpack("c")[0], rest: nil}
    when Bare::DataTypes::I16
      return {value: msg.unpack('s<')[0], rest: nil}
    when Bare::DataTypes::I32
      return {value: msg.unpack('l<')[0], rest: nil}
    when Bare::DataTypes::I64
      return {value: msg.unpack('q<')[0], rest: nil}
    when Bare::DataTypes::Bool
      return {value: msg == "\x00\x00" ? false : true, rest: nil}
    when Bare::DataTypes::Uint
      ints = msg.unpack("C*")
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
      return {value: sum, rest: msg[(i+1)..msg.size] }
    else
      raise("Unknown type found in schema: #{schema}")
    end
  end

  class DataTypes
    class Uint
    end

    class U8
    end

    class U16
    end

    class U32
    end

    class U64
    end

    class I8
    end

    class I16
    end

    class I32
    end

    class I64
    end

    class Bool
    end

    class Array
      def initialize(type)
        @type = type
      end
    end

  end
end

def get_next_7_bits_as_byte(integer, base = 128)
  # Base is the initial value of the byte before
  # before |'ing it with 7bits from the integer
  groups_of_7 = (integer.size*8) / 7 + (integer.size % 7 == 0 ? 0 : 1)
  0.upto(groups_of_7 - 1) do |group_number|
    byte = base
    0.upto(7).each do |bit_number|
      byte = byte | (integer[group_number * 7 + bit_number] << bit_number)
    end
    yield(byte)
  end
end
