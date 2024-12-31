# frozen_string_literal: true

require 'test_helper'
require_relative "sql_parser"

class YaparcQueryTest < Test::Unit::TestCase
  include ::Yaparc

  def test_op
    op = SQL::Op.new
    result = op.parse('<')
    assert_instance_of OK, result
    assert_equal :lesser, result.value
    result = op.parse('<=')
    assert_instance_of OK, result
    assert_equal :lesser_eq, result.value
  end

  def test_term
    term = SQL::Term.new
    result = term.parse('abc')
    assert_instance_of OK, result
    assert_equal 'abc', result.value
  end

  def test_path_expression
    path = SQL::PathExpression.new
    result = path.parse('/xyz')
    assert_instance_of OK, result
    assert_equal ['xyz'], result.value
    result = path.parse('/abc/def')
    assert_instance_of OK, result
    assert_equal %w[abc def], result.value
  end

  def test_from_expression
    path = SQL::FromExpression.new
    result = path.parse('from /xyz')
    assert_instance_of OK, result
    assert_equal ['xyz'], result.value
    result = path.parse('from /abc/def')
    assert_instance_of OK, result
    assert_equal %w[abc def], result.value
  end

  def test_search_cond
    search = SQL::SearchCond.new
    result = search.parse('abc <> xyz')
    assert_instance_of OK, result
    assert_equal Hash[operator: :not, args: %w[abc xyz]], result.value

    result = search.parse('(NOT abc <> xyz)')
    assert_instance_of OK, result
    assert_equal Hash[logic: :not, conditions: [{ operator: :not, args: %w[abc xyz] }]], result.value
    result = search.parse('(abc <> xyz AND abc > xyz)')
    assert_instance_of OK, result
    assert_equal Hash[
                      logic: :and, conditions: [{ operator: :not, args: %w[abc xyz] },
                                                { operator: :greater, args: %w[abc xyz] }]
                     ], result.value
  end

  def test_query_body
    query = SQL::QueryBody.new
    result = query.parse('select abc from /xyz')
    assert_instance_of OK, result
    assert_equal Hash[from: ['xyz'], where: [], select: ['abc']], result.value
    result = query.parse('select abc from /xyz/fgh')
    assert_instance_of OK, result
    assert_equal Hash[from: %w[xyz fgh], where: [], select: ['abc']], result.value
  end
end
