def create_user_type_name
  upper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  lower  = upper.downcase
  digit = "0123456789"

  name = upper[rand(upper.size)]
  loop do
    if rand(50) < 5
      break
    end
    num = rand(3)
    if num  == 0
      name << upper[rand(upper.size)]
    elsif num == 1
      name << lower[rand(lower.size)]
    else
      name << digit[rand(digit.size)]
    end
  end
  name.to_sym
end

