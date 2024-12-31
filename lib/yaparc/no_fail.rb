require_relative "parsable"

module Yaparc
  # hutton92:_higher_order_funct_parsin,p.19
  # https://www.cambridge.org/core/journals/journal-of-functional-programming/article/higherorder-functions-for-parsing/0490F2C8511F7625F9FC15BFFEDBB0AA
  class NoFail
    include Parsable

    def initialize(parser)
      @parser = lambda do |input|
        result = parser.parse(input)
        if result.instance_of?(Fail)
          Error.new(value: result.value, input: result.input)
        else
          Succeed.new(result.value)
        end
      end
    end
  end
end
