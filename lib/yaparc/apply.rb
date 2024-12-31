require_relative "parsable"

module Yaparc
  class Apply
    include Parsable

    def initialize(parser)
      @parser = lambda do |input|
        result = parser.parse(input)
        if result.instance_of?(OK)
          Succeed.new(yield(result.value)).parse(result.input)
        else
          FailParser.new.parse(input)
        end
      end
    end
  end
end
