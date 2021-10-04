require_relative '../../src/lib/bare-rb'
require_relative './monkey_patch'
require_relative './grammar_util'

def get_type(depth, names = [], can_be_symbol = true)
  if names.size == 0
    can_be_symbol = false
  end
  terminators = [BareTypes::Data, BareTypes::DataFixedLen,
                 BareTypes::U8, BareTypes::U16, BareTypes::U32, BareTypes::U64,
                 BareTypes::I8, BareTypes::I16, BareTypes::I32, BareTypes::I64,
                 BareTypes::F32, BareTypes::F64]
  aggregates = [BareTypes::Array, BareTypes::ArrayFixedLen,
                BareTypes::Struct]

  all = terminators + aggregates

  # 1/5 changes of a reference
  x = if rand(5) == 0 && names.size != 1
        names[rand(names.size)]
      elsif depth >= 10 # if depth >= 10 only use terminating types
        all[rand(terminators.size)].make(depth+1, names)
      else
        # otherwise random type
        all[rand(all.size)].make(depth+1, names)
      end
  x
end

def create_schema
  names = []
  schema = {}
  0.upto(rand(5)) do
    names << create_user_type_name.to_sym
  end
  names.each do |name|
    without_this_name = names.select {|n| n != name}
    schema[name] = get_type(0, without_this_name, false)
  end
  Bare.Schema(schema)
end