require_relative "parsable"

module Yaparc
  # Refer to http://www.cs.nott.ac.uk/~gmh/monparsing.pdf, p.23
  class Identifier
    include Yaparc::Parsable

    IDENTIFIER_REGEX = /\A[a-zA-Z_]+[a-zA-Z0-9_]*/

    def initialize(regex: nil, exclude: nil)
      identifier_regex = ::Yaparc::Regex.new(regex || IDENTIFIER_REGEX)

      tokenizer = Tokenize.new(identifier_regex)

      unless exclude
        @parser = proc { tokenizer }
        return
      end

      @parser = lambda do |input|
        keyword_parsers = exclude.map { |keyword| Yaparc::String.new(keyword) }

        case result = Yaparc::Alt.new(*keyword_parsers).parse(input)
        when Yaparc::OK
          Yaparc::FailParser.new
        else # Fail or Error
          tokenizer
        end
      end
    end
  end
end
