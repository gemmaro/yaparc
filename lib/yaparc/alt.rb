require_relative 'parsable'

module Yaparc
  class Alt
    include Parsable

    def initialize(*parsers)
      @parser = lambda do |input|
        final_result = Fail.new(input:)
        parsers.each do |parser|
          case result = parser.parse(input)
          in Fail
            next
          in OK
            break final_result = result
          end
        end
        final_result
      end
    end
  end
end
