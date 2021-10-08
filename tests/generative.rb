require_relative '../src/lib/bare-rb'
require 'minitest/autorun'

class TestGen < Minitest::Test
  def test_gen

    tests = 0
    0.upto(1000) do
      file = Tempfile.new('schema.bare')
      file.open

      puts "Done with #{tests}"

      begin
        schema, _binary = Bare.generative_test
        file.truncate(0)
        file.write(schema.to_s)
        file.close

        parsed_schema = Bare.parse_schema(file.path)
        parsed_schema.types.keys.each do |schema_entry|
          input = schema[schema_entry].create_input
          binary = Bare.encode(input, schema[schema_entry])
          output = Bare.decode(binary, schema[schema_entry])
          if input != output
            puts schema.to_s
          end
          assert_equal input, output, "Something went wrong.. input != output for #{schema_entry}"
          tests += 1
        end
      rescue CircularSchema => e
        puts "Generator generated a circular schema..."
      rescue Exception => e
        puts "Something unexpected went wrong. This is a bug."
        puts schema.to_s
        raise e
        break
      end
    end
    puts "Completed #{tests} tests"
  end
end