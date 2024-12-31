require_relative "parsable"

module Yaparc
  class Space
    include Parsable

    def initialize
      @parser = proc { Regex.new(/\A */) }
    end
  end
end
