require_relative 'parsable'

module Yaparc
  class Succeed
    include Parsable

    attr_reader :remaining

    def initialize(value, remaining = nil)
      @parser = ->(input) { OK.new(value:, input:) }
      @remaining = remaining
    end
  end
end
