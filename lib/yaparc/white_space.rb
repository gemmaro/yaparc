require_relative "parsable"

module Yaparc
  class WhiteSpace
    include Parsable

    def initialize
      @parser = proc { Regex.new(/\A[\t\n ]*/) }
    end
  end
end
