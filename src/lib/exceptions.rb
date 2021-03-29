
class BareException < StandardError
  def initialize(msg=nil)
    super
  end
end

class FixedDataSizeWrong < BareException
  def initialize(msg=nil)
    super
  end
end

class NoTypeProvided < BareException
  def initialize(msg = nil)
    super
  end
end

class SchemaParsingException < BareException
  def initialize(msg=nil)
    super
  end
end

class VoidUsedOutsideTaggedSet < BareException
  def initialize(msg =  "Any type which is ultimately a void type (either directly or through user-defined types) may not be used as an optional type, struct member, array member, or map key or value. Void types may only be used as members of the set of types in a tagged union.")
    super
  end
end

class MinimumSizeError < BareException
  def initialize(msg = "Schema object has minimum size of 1")
    super
  end
end
class MaximumSizeError < BareException
  def initialize(msg = "Object too large to encode as given type")
    super
  end
end

class MapKeyError < BareException
  def initialize(msg = "Map keys must be a none data or data[len] primitive")
    super
  end
end

class EnumValueError < BareException
  def initialize(msg = "Enums cannot have two identical values")
    super
  end
end

class SchemaMismatch < BareException
  def initialize(msg = "Some mismatch between data and schema has occurred")
    super
  end
end