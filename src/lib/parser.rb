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
        tokens = tokens[3..tokens.size]
      else
        enum_hash[count] = tokens[0]
        count += 1
        tokens = tokens[1..tokens.size]
      end
    end
    enum = Bare.Enum(enum_hash)
    return tokens[1..tokens.size], enum
  end

  def parse_union(tokens)
    count = 0
    union_hash = {}
    # type A_UNION ( int | uint | data = 7 | f32 )
    while tokens[0] != :close_paren
      if tokens[0] == :bar
        tokens = tokens[1..tokens.size]
      else
        if tokens[1] == :equal
          raise SchemaParsingException.new("Equals sign in union must be followed by a number") unless tokens[2].is_a?(Numeric)
          count = tokens[2]
          tokens, type = self.parse(tokens)
          tokens = tokens[2..tokens.size]
          union_hash[count] = type
          count += 1
        else
          tokens, type = self.parse(tokens)
          union_hash[count] = type
          count += 1
        end
      end
    end
    return tokens, union_hash
  end

  def parse_struct(tokens)
    struct_fields = {}
    while tokens.size >= 2 and tokens[1] == :colon
      name = tokens[0]
      tokens, type = self.parse(tokens[2..tokens.size])
      struct_fields[name.to_sym] = type
    end
    return tokens[1..tokens.size], struct_fields
  end

  def parse(tokens)
    while tokens.size > 0
      if tokens[0] == "type"
        name = tokens[1]
        tokens, type = self.parse(tokens[2..tokens.size])
        @definitions[name.to_sym] = type
      elsif tokens[0] == "map"
        raise SchemaParsingException.new("Map must be followed by a '[' eg. map[string]data") if tokens[1] != :open_brace
        tokens, map_from_type = parse(tokens[2..tokens.size])
        raise SchemaParsingException.new("Map to type must be followed by a ']' eg. map[string]data") if tokens[0] != :close_brace
        tokens, map_to_type = parse(tokens[1..tokens.size])
        return tokens, Bare.Map(map_from_type, map_to_type)
      elsif tokens[0] == "data" && tokens.size > 3 && tokens[1] == :less_than
        raise SchemaParsingException.new("data< must be followed by a number for a fixed sized bare data") unless tokens[2].is_a?(Numeric)
        raise SchemaParsingException.new("data<# must be followed by a >") unless tokens[3] == :greater_than
        return tokens[4..tokens.size], Bare.DataFixedLen(tokens[2])
      elsif tokens[0] == "enum"
        name = tokens[1]
        raise SchemaParsingException.new("Enum must be followed by a '{'") if tokens[2] != :open_block
        tokens, enum = parse_enum(tokens[3..tokens.size])
        @definitions[name.to_sym] = enum
      elsif tokens[0] == "optional"
        raise SchemaParsingException.new("Optional must be followed by a '< TYPE > you are missing the first <'") if tokens[1] != :less_than
        tokens, optional_type = self.parse(tokens[2..tokens.size])
        raise SchemaParsingException.new("Optional must be followed by a '< TYPE >' you are missing the last >") if tokens[0] != :greater_than
        return tokens[1..tokens.size], Bare.Optional(optional_type)
      elsif tokens[0] == :open_brace
        if tokens[1].is_a?(Numeric)
          size = tokens[1]
          raise SchemaParsingException.new("Fixed Length Array size must be followed by a ']'") if tokens[2] != :close_brace
          tokens, arr_type = parse(tokens[3..tokens.size])
          return tokens, Bare.ArrayFixedLen(arr_type, size)
        else
          tokens, arr_type = parse(tokens[2..tokens.size])
          return tokens, Bare.Array(arr_type)
        end
      elsif tokens[0] == :open_paren
        tokens, union_hash = parse_union(tokens[1..tokens.size])
        raise SchemaParsingException.new("Union must be followed by a ')'") if tokens[0] != :close_paren
        return tokens[1..tokens.size], Bare.Union(union_hash)
      elsif tokens[0] == :open_block
        tokens, struct_fields = parse_struct(tokens[1..tokens.size])
        strct = Bare.Struct(struct_fields)
        return tokens, strct
      elsif @primitives.include?(tokens[0])
        type = @primitives[tokens[0]]
        return tokens[1..tokens.size], type
      elsif @definitions.keys.include?(tokens[0].to_sym) # User defined type
        return tokens[1..tokens.size], @definitions[tokens[0].to_sym]
      elsif tokens[0].is_a?(String) && tokens[0][0].upcase == tokens[0][0] # Not yet defined user type
        return tokens[1..tokens.size], tokens[0].to_sym
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