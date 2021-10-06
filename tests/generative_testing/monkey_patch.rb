require_relative '../../src/lib/bare-rb'
require_relative './grammar_util'

# 10MB max data size
DATA_MAX_SIZE = 5
ARRAY_MAX_SIZE = 3
STRUCT_FIELDS_MAX = 1

# Monkey patch every bare class to include make and create_input
# make - a factory to create a random variant of the bare class
# create_input - creates an input that could be used with Bare.Encode for this type

class BareTypes::Reference
  def create_input
    self.ref.create_input
  end
  def self.make(depth, names)
    self.ref.make(depth, names)
  end
end

# region Integers
class BareTypes::U8
  def self.make(depth, names)
    BareTypes::U8.new
  end

  def create_input
    rand(256)
  end
end

class BareTypes::U16
  def self.make(depth, names)
    BareTypes::U16.new
  end

  def create_input
    rand(2**16)
  end
end

class BareTypes::U32
  def self.make(depth, names)
    BareTypes::U32.new
  end

  def create_input
    rand(2**32)
  end
end

class BareTypes::U64
  def self.make(depth, names)
    BareTypes::U64.new
  end

  def create_input
    rand(2**64)
  end
end

class BareTypes::I8
  def self.make(depth, names)
    BareTypes::I8.new
  end

  def create_input
    rand(2 ** 8) - (2 ** 7)
  end
end

class BareTypes::I16
  def self.make(depth, names)
    BareTypes::I16.new
  end

  def create_input
    rand(2 ** 16) - (2 ** 15)
  end
end

class BareTypes::I32
  def self.make(depth, names)
    BareTypes::I32.new
  end

  def create_input
    rand(2 ** 32) - (2 ** 31)
  end
end

class BareTypes::I64
  def self.make(depth, names)
    BareTypes::I64.new
  end

  def create_input
    rand(2 ** 64) - (2 ** 63)
  end
end
# endregion

#region Floats
class BareTypes::F32
  def self.make(depth, names)
    self.new
  end

  def create_input
    float = nil
    loop do
      input = [rand(266), rand(266), rand(266), rand(266)]
      float = input.pack("cccc").unpack('e')
      if float[0] == float[0] && !float[0].nan?
        break
      end
    end
    float[0]
  end
end

class BareTypes::F64
  def self.make(depth, names)
    self.new
  end

  def create_input
    float = nil
    loop do
      input = [rand(266), rand(266), rand(266), rand(266), rand(266), rand(266), rand(266), rand(266)]
      float = input.pack("cccccccc").unpack('E')
      if float[0] == float[0] && !float[0].nan?
        break
      end
    end
    float[0]
  end
end
#endregion

#region Data
class BareTypes::DataFixedLen
  def self.make(depth, names)
    length = rand(max=DATA_MAX_SIZE) + 1
    self.new(length)
  end

  def create_input
    # 100 random bytes
    arr = []
    0.upto(length-1).each do |i|
      arr << i % 256
    end
    arr.pack('c*')
  end
end

class BareTypes::Data
  def self.make(depth, names)
    self.new
  end

  def create_input
    arr = []
    0.upto(rand(DATA_MAX_SIZE)).each do |i|
      arr << i % 256
    end
    arr.pack('c*')
  end
end
#endregion

#region Array
class BareTypes::Array
  def self.make(depth, names)
    BareTypes::Array.new(get_type(depth+1, names))
  end

  def create_input
    count = rand(ARRAY_MAX_SIZE) + 1
    arr = []
    0.upto(count) do
      arr << @type.create_input
    end
    arr
  end
end

class BareTypes::ArrayFixedLen
  def self.make(depth, names)
    self.new(get_type(depth+1, names,), rand(ARRAY_MAX_SIZE) + 1)
  end

  def create_input
    arr = []
    0.upto(@size-1) do
      arr << @type.create_input
    end
    arr
  end
end
#endregion

#region Agg Types

class BareTypes::Struct
  def self.make(depth, names)
    hash = {}
    0.upto(rand(STRUCT_FIELDS_MAX) + 1) do
      hash[create_user_type_name.to_sym] = get_type(depth+1, names)
    end
    self.new(hash)
  end
  def create_input
    input = {}
    @mapping.keys.each do |name|
      input[name] = @mapping[name].create_input
    end
    input
  end
end

# endregion