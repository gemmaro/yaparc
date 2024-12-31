require_relative 'parsable'

module Yaparc
  class AbstractParser
    include Parsable

    def parse(input)
      tree = @parser.call.parse(input)
      @tree = if block_given?
                yield tree
              else
                tree
              end
    end
  end
end
