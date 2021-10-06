require_relative './gen'
require 'tempfile'
require 'minitest/autorun'

class TestGen < Minitest::Test
  def test_gen

    0.upto(1000) do
      file = Tempfile.new('schema.bare')
      file.open

      begin
        schema = create_schema
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
        end
        #
      rescue Exception => e
        puts "Schema:"
        puts schema.to_s
        puts e.inspect
        file.close
      ensure
      end
    end
  end
end