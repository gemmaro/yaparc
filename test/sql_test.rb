# frozen_string_literal: true

require 'test_helper'

###  c.f. http://www11.plala.or.jp/sotsuken/db/sql.html
###
###  query_body := select_expression from_expression where_expression
###  select_expression := 'select' term_sequence
###  term_sequence := term[,term_sequence]*
###  from_expression := 'from' path_expression[, path_expression]*
###  path_expression := '/' term [path_expression]*
###  where_expression :=
###                    | search_cond
###  search_cond := term op term
###              | ( NOT search_cond )
###              | ( search_cond AND search_cond )
###              | ( search_cond OR search_cond )
###              | EXISTS ( query_body )
###              | term op ANY ( query_body )
###              | term op ALL ( query_body )
###              | term IN ( query_body )
###  term := any_characters
###  op := <> | = | <  | > | <= | >=

module SQL
  KEYWORDS = %w[NOT AND OR ALL IN select from where EXISTS]

  ###  query_body := select_expression from_expression where_expression
  class QueryBody
    include Yaparc::Parsable

    def initialize
      @parser = lambda do |_input|
        Yaparc::Seq.new(SelectExpression.new,
                        FromExpression.new,
                        WhereExpression.new) do |select, from, where|
          { select:, from:, where: }
        end
      end
    end
  end

  ###  select_expression := 'select' term_sequence
  class SelectExpression
    include Yaparc::Parsable

    def initialize
      @parser = lambda do |_input|
        Yaparc::Seq.new(
          Yaparc::Symbol.new('select'),
          TermSequence.new
        ) do |_, terms|
          terms
        end
      end
    end
  end

  ###  term_sequence := term[,term_sequence]*
  class TermSequence
    include Yaparc::Parsable

    def initialize
      @parser = lambda do |_input|
        Yaparc::Seq.new(
          Term.new,
          Yaparc::Many.new(
            Yaparc::Seq.new(
              Yaparc::Symbol.new(','),
              TermSequence.new
            ) do |_, terms|
              terms
            end
          )
        ) do |term, terms|
          [term] + terms
        end
      end
    end
  end

  ###  from_expression := 'from' path_expression[, path_expression]*
  class FromExpression
    include Yaparc::Parsable

    def initialize
      @parser = lambda do |_input|
        Yaparc::Seq.new(
          Yaparc::Symbol.new('from'),
          PathExpression.new,
          Yaparc::Many.new(
            Yaparc::Seq.new(
              Yaparc::Symbol.new(','),
              PathExpression.new
            ) do |_, path|
              [path]
            end
          )
        ) do |_, path, paths|
          path + paths
        end
      end
    end
  end

  ###  path_expression := '/' term [path_expression]*
  class PathExpression
    include Yaparc::Parsable

    def initialize
      @parser = lambda do |_input|
        Yaparc::Seq.new(
          Yaparc::Symbol.new('/'),
          Term.new,
          Yaparc::Many.new(
            PathExpression.new do |path|
              path
            end
          )
        ) do |_, term, paths|
          [term] + paths
        end
      end
    end
  end

  ###  where_expression :=
  ###                    | search_cond
  class WhereExpression
    include Yaparc::Parsable

    def initialize
      @parser = lambda do |_input|
        Yaparc::Many.new(SearchCond.new)
      end
    end
  end

  ###  term := any_characters
  class Term
    include Yaparc::Parsable

    def initialize # (*keywords)
      @parser = lambda do |_input|
        #        Yaparc::Identifier.new(*KEYWORDS)
        Yaparc::Identifier.new(exclude: KEYWORDS)
      end
    end
  end

  ###  search_cond := term op term
  ###              | ( NOT search_cond )
  ###              | ( search_cond AND search_cond )
  ###              | ( search_cond OR search_cond )
  ###              | EXISTS ( query_body )
  ###              | term op ANY ( query_body )
  ###              | term op ALL ( query_body )
  ###              | term IN ( query_body )

  class SearchCond
    include Yaparc::Parsable

    def initialize
      @parser = lambda do |_input|
        Yaparc::Alt.new(
          Yaparc::Seq.new(Term.new,
                          Op.new,
                          Term.new) do |term1, op, term2|
            { operator: op, args: [term1, term2] }
          end,
          Yaparc::Seq.new(Yaparc::Symbol.new('('),
                          Yaparc::Symbol.new('NOT'),
                          SearchCond.new,
                          Yaparc::Symbol.new(')')) do |_, _, cond, _|
            { logic: :not, conditions: [cond] }
          end,
          Yaparc::Seq.new(Yaparc::Symbol.new('('),
                          SearchCond.new,
                          Yaparc::Symbol.new('AND'),
                          SearchCond.new,
                          Yaparc::Symbol.new(')')) do |_, cond1, _, cond2, _|
            { logic: :and, conditions: [cond1, cond2] }
          end,
          Yaparc::Seq.new(Yaparc::Symbol.new('('),
                          SearchCond.new,
                          Yaparc::Symbol.new('OR'),
                          SearchCond.new,
                          Yaparc::Symbol.new(')')) do |_, cond1, _, cond2, _|
            { logic: :or, conditions: [cond1, cond2] }
          end,
          Yaparc::Seq.new(Yaparc::Symbol.new('EXISTS'),
                          Yaparc::Symbol.new('('),
                          QueryBody.new,
                          Yaparc::Symbol.new(')')) do |_, _, body, _|
            { logic: :exits, condition: body }
          end,
          # term op ANY ( query_body )
          Yaparc::Seq.new(Term.new,
                          Op.new,
                          Yaparc::Symbol.new('ANY'),
                          Yaparc::Symbol.new('('),
                          QueryBody.new,
                          Yaparc::Symbol.new(')')) do |term, op, _, _, body, _|
            { operator: op,
              term1: term,
              term2: { logic: :any, condition: body } }
          end,
          # term op ALL ( query_body )
          Yaparc::Seq.new(Term.new,
                          Op.new,
                          Yaparc::Symbol.new('ALL'),
                          Yaparc::Symbol.new('('),
                          QueryBody.new,
                          Yaparc::Symbol.new(')')) do |term, op, _, _, body, _|
            { operator: op,
              term1: term,
              term2: { logic: :ALL, condition: body } }
          end,
          # term IN ( query_body )
          Yaparc::Seq.new(Term.new,
                          Op.new,
                          Yaparc::Symbol.new('IN'),
                          Yaparc::Symbol.new('('),
                          QueryBody.new,
                          Yaparc::Symbol.new(')')) do |term, op, _, _, body, _|
            { operator: op,
              term1: term,
              term2: { logic: :IN, condition: body } }
          end
        )
      end
    end
  end

  ###  op := <> | = | <  | > | <= | >=
  class Op
    include Yaparc::Parsable

    def initialize
      @parser = lambda do |_input|
        Yaparc::Alt.new(
          Yaparc::Apply.new(Yaparc::Symbol.new('<>')) { |_| :not },
          Yaparc::Apply.new(Yaparc::Symbol.new('<=')) { |_| :lesser_eq },
          Yaparc::Apply.new(Yaparc::Symbol.new('>=')) { |_| :greater_eq },
          Yaparc::Apply.new(Yaparc::Symbol.new('<')) { |_| :lesser },
          Yaparc::Apply.new(Yaparc::Symbol.new('>')) { |_| :greater }
        )
      end
    end
  end
end # of SQL

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
