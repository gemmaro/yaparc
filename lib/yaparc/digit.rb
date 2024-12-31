require_relative "parsable"

module Yaparc
  class Digit
    include Parsable

    def initialize
      @parser = proc { Satisfy.new(IS_DIGIT) }
    end
  end
end
