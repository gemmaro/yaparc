require_relative 'parsable'

module Yaparc
  class ZeroOne
    include Parsable

    def initialize(parser, identity = [])
      @parser = lambda do |input|
        case (result = parser.parse(input))
        in Fail
          OK.new(value: identity, input:)
        in Error
          Error.new(value: result.value, input: result.input)
        in OK
          result
        end
      end
    end
  end
end
