class Bare
  def self.encode(msg, schema)
    return schema.encode(msg)
  end

  def self.decode(msg, schema)
    return schema.decode(msg)[:value]
  end

  class DataTypes
    class Uint
      def encode(msg)
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
      end
      def decode(msg)
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
        return {value: sum, rest: msg[(i + 1)..msg.size]}
      end
    end

    class U8
      def encode(msg)
        return [msg].pack("C")
      end
      def decode(msg)
        return {value: msg[0].unpack("C")[0], rest: msg[1..msg.size]}
      end
    end

    class U16
      def encode(msg)
        return [msg].pack("v")
      end
      def decode(msg)
        return {value: msg.unpack("v")[0], rest: msg[2..msg.size]}
      end
    end

    class U32
      def encode(msg)
        return [msg].pack("V")
      end
      def decode(msg)
        return {value: msg.unpack("V")[0], rest: msg[4..msg.size]}
      end
    end

    class U64
      def encode(msg)
        return [msg].pack("Q")
      end
      def decode(msg)
        return {value: msg.unpack("Q")[0], rest: [8..msg.size]}
      end
    end

    class I8
      def encode(msg)
        return [msg].pack("c")
      end
      def decode(msg)
        return {value: msg[0].unpack("c")[0], rest: msg[1..msg.size]}
      end
    end

    class I16
      def encode(msg)
        return [msg].pack("s<")
      end
      def decode(msg)
        return {value: msg.unpack('s<')[0], rest: msg[2..msg.size]}
      end
    end

    class I32
      def encode(msg)
        return [msg].pack("l<")
      end
      def decode(msg)
        return {value: msg.unpack('l<')[0], rest: msg[4..msg.size]}
      end
    end

    class I64
      def encode(msg)
        return [msg].pack("q<")
      end
      def decode(msg)
        return {value: msg.unpack('q<')[0], rest: msg[8..msg.size]}
      end
    end

    class Bool
      def encode(msg)
        return msg ? "\xFF\xFF".b : "\x00\x00".b
      end
      def decode(msg)
        return {value: msg == "\x00\x00" ? false : true, rest: msg[1..msg.size]}
      end
    end

    class FixedLenArray
      def initialize(type, size)
        @type = type
        @size = size
      end

      def encode(arr)
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

  end
  end

  def get_next_7_bits_as_byte(integer, base = 128)
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
