require_relative 'parsable'

module Yaparc
  class Seq
    include Parsable

    def initialize(*parsers)
      @parser = lambda do |input|
        args = []
        initial_result = OK.new(input:)
        final_result = parsers.inject(initial_result) do |subsequent, parser|
          result = parser.parse(subsequent.input)
          break Fail.new(input: subsequent.input) if result.instance_of?(Fail)

          args << result.value
          result
        end

        case final_result
        in Fail
          Fail.new(input: final_result.input)
        in OK
          final_value = if block_given?
                          yield(*args)
                        else
                          args.last
                        end
          OK.new(value: final_value, input: final_result.input)
        end
      end
    end
  end
end
