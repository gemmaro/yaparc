require_relative "parsable"

module Yaparc
  class Tokenize
    include Parsable

    attr_writer :prefix, :postfix

    def initialize(parser, prefix: nil, postfix: nil)
      @parser = lambda do |_input|
        @prefix = prefix || WhiteSpace.new
        @postfix = postfix || WhiteSpace.new
        block_given? and yield self
        Seq.new(@prefix, parser, @postfix) { |_, vs, _| vs }
      end
    end
  end
end
