require_relative "parsable"

module Yaparc
  class CR
    include Parsable

    def initialize
      @parser = proc { Regex.new(/\A[ \t]+\n[ \t\n]+/) }
    end
  end
end
