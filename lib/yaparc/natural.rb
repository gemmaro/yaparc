require_relative "parsable"

module Yaparc
  class Natural
    include Parsable

    # Accepts Yaparc::Tokenize::new's keyword arguments.
    def initialize(**args)
      @parser = proc { Tokenize.new(Nat.new, **args) }
    end
  end
end
