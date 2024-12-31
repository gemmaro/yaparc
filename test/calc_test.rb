# frozen_string_literal: true

require 'test_helper'

module Calc
  class Expr
    include Yaparc::Parsable

    def initialize
      @parser = lambda do |_input|
        Yaparc::Alt.new(
          Yaparc::Seq.new(Term.new,
                          Yaparc::Symbol.new('+'),
                          Expr.new) do |term, _, expr|
            ['+', term, expr]
          end,
          Term.new
        )
      end
    end

    def evaluate(input)
      result = parse(input)
      tree = result.value
      eval_tree(tree)
    end

    def eval_tree(tree)
      case tree
      when Array
        case tree[0]
        when '+'
          eval_tree(tree[1]) + eval_tree(tree[2])
        when '-'
          eval_tree(tree[1]) - eval_tree(tree[2])
        when '*'
          eval_tree(tree[1]) * eval_tree(tree[2])
        when '/'
          eval_tree(tree[1]) / eval_tree(tree[2])
        end
      else
        tree
      end
    end
  end

  class Term
    include Yaparc::Parsable

    def initialize
      @parser = lambda do |_input|
        Yaparc::Alt.new(
          Yaparc::Seq.new(Factor.new,
                          Yaparc::Symbol.new('*'),
                          Term.new) do |factor, _, term|
            ['*', factor, term]
          end,
          Factor.new
        )
      end
    end
  end

  class Factor
    include Yaparc::Parsable

    def initialize
      @parser = lambda do |_input|
        Yaparc::Alt.new(
          Yaparc::Seq.new(
            Yaparc::Symbol.new('('),
            Expr.new,
            Yaparc::Symbol.new(')')
          ) do |_, expr, _|
            expr
          end,
          Yaparc::Natural.new
        )
      end
    end
  end
end # of Calc

class YaparcCalcTest < Test::Unit::TestCase
  include ::Yaparc

  def setup
    @expr = Calc::Expr.new
    @factor = Calc::Factor.new
  end

  def test_expr
    result = @expr.parse('1 + 2 ')
    assert_instance_of OK,  result
    assert_equal ['+', 1, 2], result.value
    assert_equal '', result.input
    assert_equal 3, @expr.evaluate('1 + 2 ')
    assert_equal 9, @expr.evaluate('(1 + 2) * 3 ')
  end

  def test_factor
    result = @factor.parse('1')
    assert_equal 1, result.value
    assert_equal '', result.input

    result = @factor.parse('( 1 )')
    assert_equal 1, result.value
    assert_equal '', result.input

    result = @factor.parse('( 312 )')
    assert_equal 312,  result.value
    assert_equal '', result.input
  end
end
