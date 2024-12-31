require_relative 'parsable'

module Yaparc
  class Item
    include Parsable

    def initialize
      @parser = lambda do |input|
        if input.nil? || input.empty?
          Fail.new(input:)
        else
          OK.new(value: input[0], input: input[1..])
        end
      end
    end
  end
end
