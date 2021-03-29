require_relative './exceptions'

def lexer(path)
  tokens = []
  line_num = 0
  File.open(path).each do |line|
    while line.size > 0
      if /^#/.match(line)
        break
      elsif /^\n/.match(line)
        break
      elsif /^ /.match(line)
        line = line[1..line.size]
      elsif /^</.match(line)
        line = line[1..line.size]
        tokens << :less_than
      elsif /^>/.match(line)
        line = line[1..line.size]
        tokens << :greater_than
        next
      elsif /^{/.match(line)
        line = line[1..line.size]
        tokens << :open_block
      elsif /^=/.match(line)
        line = line[1..line.size]
        tokens << :equal
      elsif /^}/.match(line)
        line = line[1..line.size]
        tokens << :close_block
      elsif /^\[/.match(line)
        line = line[1..line.size]
        tokens << :open_brace
      elsif /^\]/.match(line)
        line = line[1..line.size]
        tokens << :close_brace
      elsif /^\(/.match(line)
        line = line[1..line.size]
        tokens << :open_paren
      elsif /^\)/.match(line)
        line = line[1..line.size]
        tokens << :close_paren
      elsif /^\|/.match(line)
        line = line[1..line.size]
        tokens << :bar
      elsif match = /^([0-9]+)/.match(line)
        tokens << match[0].to_i
        line = line[(match[0].size)..line.size]
        next
      elsif match = /^[a-z,A-Z,_][_,a-z,A-Z,0-9]+/.match(line)
        tokens << match[0]
        line = line[(match[0].size)..line.size]
      elsif /:/.match(line)
        tokens << :colon
        line = line[1..line.size]
      else
        raise SchemaParsingException.new("Unable to lex line #{line_num} near #{line.inspect}")
      end
    end
    line_num += 1
  end
  return tokens
end