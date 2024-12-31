# frozen_string_literal: true

require 'test_helper'
require_relative "lambda_parser"

class LambdaIdentifierParserTest < Test::Unit::TestCase
  include ::Yaparc

  def setup
    @parser = LambdaParser::Identifier.new
  end

  def test_identifier
    result = @parser.parse('identifier')
    assert_instance_of OK, result
    result = @parser.parse('lambda')
    assert_instance_of Fail, result

    result = @parser.parse(' identifier')
    assert_instance_of OK, result
    result = @parser.parse(' identifier ')
    assert_instance_of OK, result
    result = @parser.parse('identifier ')
    assert_instance_of OK, result
  end
end

class LambdaExpressionParserTest < Test::Unit::TestCase
  include ::Yaparc

  def setup
    @parser = LambdaParser::Expression.new
  end

  def test_expression
    assert_instance_of OK, @parser.parse('identifier')
    assert_instance_of OK, @parser.parse('(lambda (x) x)')
    assert_instance_of OK, @parser.parse('(apply argument)')
  end
end
