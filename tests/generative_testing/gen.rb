require_relative '../../src/lib/bare-rb'

def get_type
  types = [BareTypes::Array, BareTypes::U8, BareTypes::F32]
  types[rand(types.size)].make
end

class BareTypes::U8
  def self.make
    BareTypes::U8.new
  end

  def create_input
    rand(256)
  end
end

class BareTypes::Array
  def self.make
    BareTypes::Array.new(get_type)
  end

  def create_input
    count = rand(50)
    arr = []
    0.upto(count) do
      arr << @type.create_input
    end
    arr
  end
end

class BareTypes::F32
  def self.make
    self.new
  end

  def create_input
    float = nil
    loop do
      input = [rand(266), rand(266), rand(266), rand(266)]
      float = input.pack("cccc").unpack('e')
      if float == float
        break
      end
    end
    float
  end
end

loop do
  typ = get_type
  input = typ.create_input
  binary = Bare.encode(input, typ)
  output = Bare.decode(binary, typ)
  if input != output
    s
    puts "ALERT", input, output, typ
  end
end

# Int
# Void
# F32
# F64
# String
# Union
# Data
# Uint
# U8
# U16
# U32
# U64
# I8
# I16
# I32
# I64
# Bool
# Optional
# Map
# DataFixedLen
# Struct
# Array
# ArrayFixedLen
# Enum