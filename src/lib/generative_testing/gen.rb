require_relative '../bare-rb'
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
  if rand(5) == 0 && names.size != 1 && can_be_symbol
    names[rand(names.size)]
  elsif depth >= 10 # if depth >= 10 only use terminating types
    all[rand(terminators.size)].make(depth + 1, names)
  else
    all[rand(all.size)].make(depth + 1, names)
  end
end