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
    else
      raise("Bad schema")
    end
  end

  def self.decode(msg, schema)
    case schema

    when Bare::DataTypes::U8
      return msg[0].unpack("C")[0]
    when Bare::DataTypes::U16
      return msg.unpack("v")[0]
    when Bare::DataTypes::U32
      return msg.unpack("V")[0]
    when Bare::DataTypes::U64
      return msg.unpack("Q")[0]
    when Bare::DataTypes::I8
      return msg[0].unpack("c")[0]
    when Bare::DataTypes::I16
      return msg.unpack('s<')[0]
    when Bare::DataTypes::I32
      return msg.unpack('l<')[0]
    when Bare::DataTypes::I64
      return msg.unpack('q<')[0]

    else
      raise("Data doesn't match schema")
    end
  end


  class DataTypes
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
  end


end
