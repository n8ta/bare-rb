require_relative './exceptions'


# enum, struct, array, fixedlenarray, data<length>
class Parser

  def initialize
    @definitions = {}
    @primitives = {
        "uint" => Bare.Uint,
        "int" => Bare.Int,
        "u8" => Bare.U8,
        "u16" => Bare.U16,
        "u32" => Bare.U32,
        "u64" => Bare.U64,
        "i8" => Bare.I8,
        "i16" => Bare.I16,
        "i32" => Bare.I32,
        "i64" => Bare.I64,
        "f32" => Bare.F32,
        "f64" => Bare.F64,
        "bool" => Bare.Bool,
        "string" => Bare.String,
        "data" => Bare.Data,
        "void" => Bare.Void,
    }
  end

  def definitions
    @definitions
  end

  def parse_enum(tokens)
    enum_hash = {} # {1 => "abc", 5 => :cow, 16382 => 123}
    count = 0
    while tokens[0] != :close_block
      if tokens[1] == :equal
        name = tokens[0]
        int_repr = tokens[2]
        enum_hash[int_repr] = name
        tokens = tokens[3..]
      else
        enum_hash[count] = tokens[0]
        count += 1
        tokens = tokens[1..]
      end
    end
    enum = Bare.Enum(enum_hash)
    return tokens[1..], enum
  end

  def parse_struct(tokens)
    struct_fields = {}
    while tokens.size >= 2 and tokens[1] == :colon
      name = tokens[0]
      tokens, type = self.parse(tokens[2..])
      struct_fields[name.to_sym] = type
    end
    return tokens[1..], struct_fields
  end

  def parse(tokens)
    while tokens.size > 0
      if tokens[0] == "type"
        name = tokens[1]
        tokens, type = self.parse(tokens[2..])
        @definitions[name.to_sym] = type
      elsif tokens[0] == "map"
        raise SchemaParsingException("Map must be followed by a '[' eg. map[string]data") if tokens[1] != :open_brace
        tokens, map_from_type = parse(tokens[2..])
        raise SchemaParsingException("Map to type must be followed by a ']' eg. map[string]data") if tokens[0] != :close_brace
        tokens, map_to_type = parse(tokens[1..])
        return tokens, Bare.Map(map_from_type,map_to_type)
      elsif tokens[0] == "enum"
        name = tokens[1]
        raise SchemaParsingException("Enum must be followed by a '{'") if tokens[2] != :open_block
        tokens, enum = parse_enum(tokens[3..])
        @definitions[name.to_sym] = enum
        return tokens, enum
      elsif tokens[0] == :open_brace
        tokens, arr_type = parse(tokens[2..])
        return tokens, Bare.Array(arr_type)
      elsif tokens[0] == :open_block
        tokens, struct_fields = parse_struct(tokens[1..])
        strct = Bare.Struct(struct_fields)
        return tokens, strct
      elsif @primitives.include?(tokens[0])
        type = @primitives[tokens[0]]
        return tokens[1..], type
      else
        raise SchemaParsingException.new("Unable to parse token: #{tokens[0]}")
      end
    end
  end
end


def parser(tokens, definitions = {})
  parser = Parser.new
  parser.parse(tokens)
  return parser.definitions
end