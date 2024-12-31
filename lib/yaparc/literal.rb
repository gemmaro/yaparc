require_relative "parsable"

module Yaparc
  class Literal
    include Parsable

    def initialize(literal, case_sensitive = true)
      @parser = proc {
        Tokenize.new(Yaparc::String.new(literal, case_sensitive))
      }
    end
  end
end
