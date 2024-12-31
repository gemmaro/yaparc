# frozen_string_literal: true

require_relative 'yaparc/alt'
require_relative 'yaparc/apply'
require_relative 'yaparc/char'
require_relative 'yaparc/cr'
require_relative 'yaparc/digit'
require_relative 'yaparc/fail_parser'
require_relative 'yaparc/ident'
require_relative 'yaparc/identifier'
require_relative 'yaparc/item'
require_relative 'yaparc/literal'
require_relative 'yaparc/many'
require_relative 'yaparc/many_one'
require_relative 'yaparc/nat'
require_relative 'yaparc/natural'
require_relative 'yaparc/no_fail'
require_relative 'yaparc/parsable'
require_relative 'yaparc/regex'
require_relative 'yaparc/satisfy'
require_relative 'yaparc/seq'
require_relative 'yaparc/space'
require_relative 'yaparc/string'
require_relative 'yaparc/succeed'
require_relative 'yaparc/symbol'
require_relative 'yaparc/tokenize'
require_relative 'yaparc/white_space'
require_relative 'yaparc/zero_one'

module Yaparc
  VERSION = '0.3.0'

  begin
    base = Class.new do
      attr :input, :value

      def initialize(input:, value: nil)
        @input = input
        @value = value
      end
    end

    OK = Class.new(base)
    Fail = Class.new(base)
    Error = Class.new(base)
  end
end
