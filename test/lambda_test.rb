# frozen_string_literal: true

require 'test_helper'

=begin
<expression> ::= <identifier>
             ::= "(" lambda (<identifier> <expression> ")"
             ::= "(" <expression> <expression> ")"
=end

module LambdaParser


  class Identifier
    include Yaparc::Parsable
    RESERVED = %w{lambda}

    def initialize
      @parser = lambda do |input|
        Yaparc::Identifier.new(:exclude => RESERVED)
      end
    end
  end

  # KEYWORDS = %w{lambda}
  # <expression> ::= <identifier>
  class Expression
    include Yaparc::Parsable
    OPEN_PAREN = Yaparc::String.new("(")
    CLOSE_PAREN = Yaparc::String.new(")")

    def initialize
      @parser = lambda do |input|
        Yaparc::Alt.new(#<identifier>
                        Identifier.new,
                        #"(" lambda "(" <identifier> ")" <expression> ")"
                        Yaparc::Seq.new(OPEN_PAREN,
                                        Yaparc::String.new("lambda"),
                                        Yaparc::Tokenize.new(OPEN_PAREN),
                                        Identifier.new,
                                        CLOSE_PAREN,
                                        Expression.new),
                        #"(" <expression> <expression> ")"
                        Yaparc::Seq.new(OPEN_PAREN,
                                        Expression.new,
                                        Expression.new,
                                        CLOSE_PAREN))
      end
    end
  end
end # of LambdaParser


class LambdaIdentifierParserTest < Test::Unit::TestCase
  include ::Yaparc

  def setup
    @parser = LambdaParser::Identifier.new
  end

  def test_identifier
    result = @parser.parse("identifier")
    assert_instance_of OK, result
    result = @parser.parse("lambda")
    assert_instance_of Fail, result

    result = @parser.parse(" identifier")
    assert_instance_of OK, result
    result = @parser.parse(" identifier ")
    assert_instance_of OK, result
    result = @parser.parse("identifier ")
    assert_instance_of OK, result
  end
end

class LambdaExpressionParserTest < Test::Unit::TestCase
  include ::Yaparc

  def setup
    @parser = LambdaParser::Expression.new
  end

  def test_expression
    assert_instance_of OK, @parser.parse("identifier")
    assert_instance_of OK, @parser.parse("(lambda (x) x)")
    assert_instance_of OK, @parser.parse("(apply argument)")
  end
end
