module LambdaParser
  class Identifier
    include Yaparc::Parsable

    RESERVED = %w[lambda]

    def initialize
      @parser = proc { Yaparc::Identifier.new(exclude: RESERVED) }
    end
  end

  class Expression
    include Yaparc::Parsable

    OPEN_PAREN = Yaparc::String.new('(')
    CLOSE_PAREN = Yaparc::String.new(')')

    def initialize
      @parser = proc do
        Yaparc::Alt.new(
          Identifier.new,
          Yaparc::Seq.new(OPEN_PAREN,
                          Yaparc::String.new('lambda'),
                          Yaparc::Tokenize.new(OPEN_PAREN),
                          Identifier.new,
                          CLOSE_PAREN,
                          Expression.new),
          Yaparc::Seq.new(OPEN_PAREN,
                          Expression.new,
                          Expression.new,
                          CLOSE_PAREN)
        )
      end
    end
  end
end
