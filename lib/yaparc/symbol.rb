require_relative "parsable"

module Yaparc
  class Symbol
    include Parsable

    def initialize(literal)
      @parser = proc { Literal.new(literal) }
    end
  end
end
