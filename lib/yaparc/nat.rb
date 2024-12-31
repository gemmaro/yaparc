require_relative "parsable"

module Yaparc
  class Nat
    include Parsable

    def initialize
      @parser = proc { Seq.new(ManyOne.new(Digit.new, '')) { |vs| vs.to_i } }
    end
  end
end
