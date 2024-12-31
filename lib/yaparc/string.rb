require_relative "parsable"

module Yaparc
  class String
    include Parsable

    def initialize(string, case_sensitive = true)
      @parser = lambda do |_input|
        result = Item.new.parse(string)
        if result.instance_of?(OK)
          Seq.new(
            Char.new(result.value, case_sensitive),
            Yaparc::String.new(result.input, case_sensitive),
            Succeed.new(result.value + result.input)
          ) do |_, _, succeed_result|
            succeed_result
          end
        else
          Succeed.new(result)
        end
      end
    end
  end
end
