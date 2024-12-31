require_relative "parsable"

module Yaparc
  class Regex
    include Parsable

    def initialize(regex)
      @regex = regex
      @parser = lambda do |input|
        if match = Regexp.new(regex).match(input)
          if block_given?
            Succeed.new(yield(*match.to_a[1..])).parse(match.post_match)
          else
            OK.new(value: match[0], input: match.post_match)
          end
        else
          Fail.new(input:)
        end
      end
    end
  end
end
