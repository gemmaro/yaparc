require_relative "parsable"

module Yaparc
  class Char
    include Parsable

    def initialize(char, case_sensitive = true)
      equal_char = if case_sensitive
                     ->(i) { i == char }
                   else # in case of case-insentive
                     ->(i) { i.casecmp(char) == 0 }
                   end
      @parser = proc { Satisfy.new(equal_char) }
    end
  end
end
