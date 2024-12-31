module SQL
  KEYWORDS = %w[NOT AND OR ALL IN select from where EXISTS]

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

  class WhereExpression
    include Yaparc::Parsable

    def initialize
      @parser = lambda do |_input|
        Yaparc::Many.new(SearchCond.new)
      end
    end
  end

  class Term
    include Yaparc::Parsable

    def initialize
      @parser = proc { Yaparc::Identifier.new(exclude: KEYWORDS) }
    end
  end

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
end
