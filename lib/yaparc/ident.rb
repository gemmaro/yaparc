require_relative "parsable"

module Yaparc
  class Ident
    include Parsable

    def initialize
      @parser = proc do
        Seq.new(
          Satisfy.new(IS_LOWER),
          Many.new(Satisfy.new(IS_ALPHANUM), '')
        ) do |head, tail|
          head + tail
        end
      end
    end
  end
end
