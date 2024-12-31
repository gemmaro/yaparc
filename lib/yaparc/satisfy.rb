require_relative "parsable"

module Yaparc
  class Satisfy
    include Parsable

    def initialize(predicate)
      @parser = lambda do |input|
        result = Item.new.parse(input)

        if result.instance_of?(OK) && predicate.call(result.value)
          Succeed.new(result.value, result.input)
        else
          FailParser.new
        end
      end
    end

    def parse(input)
      case parser = @parser.call(input)
      in Succeed
        parser.parse(parser.remaining)
      in FailParser
        parser.parse(input)
      end
    end
  end
end
