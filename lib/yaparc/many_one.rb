require_relative 'parsable'

module Yaparc
  # requires at least one successfull application of parser.
  class ManyOne
    include Parsable

    def initialize(parser, identity = [])
      @parser = lambda do |_input|
        Seq.new(parser, Many.new(parser, identity)) do |head, tail|
          case head
          when ::String, ::Array, ::Integer
            head + tail
          when ::Hash
            head.merge(tail)
          else
            if tail.nil?
              head
            else
              [head] + tail
            end
          end
        end
      end
    end
  end
end
