require_relative 'parsable'

module Yaparc
  # permits zero or more applications of parser.
  class Many
    include Parsable

    def initialize(parser, identity = [])
      @parser = proc {
        Alt.new(ManyOne.new(parser, identity), Succeed.new(identity))
      }
    end
  end
end
