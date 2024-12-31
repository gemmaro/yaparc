require_relative 'parsable'

module Yaparc
  class FailParser
    include Parsable

    def initialize
      @parser = ->(input) { Fail.new(input:) }
    end
  end
end
