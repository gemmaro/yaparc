module Yaparc
  module Parsable
    IS_LOWER      = ->(c) { c >= 'a' and c <= 'z' }
    IS_ALPHANUM   = ->(c) { (c >= 'a' and c <= 'z') or (c >= '0' and c <= '9') }
    IS_DIGIT      = ->(i) { i >= '0' and i <= '9' }
    IS_SPACE      = ->(i) { i == ' ' }
    IS_WHITESPACE = ->(i) { [' ', "\n", "\t"].include?(i) }
    IS_CR         = ->(i) { i == "\n" }

    def parse(input)
      result = @parser.call(input)

      if result.respond_to?(:parse)
        result.parse(input)
      else
        result
      end
    end
  end
end
