module PrologParser
  class Program
    include Yaparc::Parsable

    def initialize
      @parser = lambda do |_input|
        Yaparc::Seq.new(Yaparc::ManyOne.new(Clause.new, [])) do |clauses|
        end
      end
    end
  end

  class Clause
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |_input|
        Yaparc::Alt.new(
          PrologParser::Fact.new,
          PrologParser::Rule.new,
          PrologParser::Query.new
        )
      end
    end
  end

  class Fact
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |_input|
        Yaparc::Seq.new(
          PrologParser::CompoundTerm.new,
          Yaparc::Literal.new('.')
        ) do |compoundterm, _|
        end
      end
    end
  end

  class CompoundTerm
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |_input|
        Yaparc::Seq.new(
          PrologParser::Atom.new,
          Yaparc::ManyOne.new(
            Yaparc::Seq.new(
              Yaparc::Literal.new('('),
              PrologParser::ArgList.new,
              Yaparc::Literal.new(')')
            ) do |_, arglist, _|
              arglist
            end
          ) do
          end
        ) do |head, tail|
        end
      end
    end
  end

  class Rule
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |_input|
        Yaparc::Seq.new(
          PrologParser::Head.new,
          Yaparc::Literal.new(':-'),
          PrologParser::Body.new,
          Yaparc::Literal.new('.')
        ) do |head, _, body, _|
        end
      end
    end
  end

  class Query
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |_input|
        Yaparc::Seq.new(
          Yaparc::Literal.new('?-'),
          PrologParser::Body.new,
          Yaparc::Literal.new('.')
        ) do |_, body, _|
        end
      end
    end
  end

  class Head
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |_input|
        PrologParser::CompoundTerm.new
      end
    end
  end

  class Body
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |_input|
        Yaparc::ManyOne.new(PrologParser::Goal.new, [])
      end
    end
  end

  class Goal
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |_input|
        Yaparc::Alt.new(
          PrologParser::CompoundTerm.new,
          Yaparc::Literal.new('!')
        )
      end
    end
  end

  class ArgList
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |_input|
        Yaparc::Seq.new(
          PrologParser::Arg.new,
          Yaparc::Many.new(
            Yaparc::Seq.new(Yaparc::Literal.new(','),
                            PrologParser::Arg.new), []
          )
        ) do |head, tail|
          [head] + tail
        end
      end
    end
  end

  class Arg
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |_input|
        Yaparc::Alt.new(
          PrologParser::Variable.new,
          PrologParser::Atom.new,
          PrologParser::List.new
        )
      end
    end
  end

  class Atom
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |_input|
        Yaparc::Seq.new(Yaparc::Regex.new(/[a-zA-Z][a-zA-Z0-9]*/)) do |ide|
        end
      end
    end
  end

  class Variable
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |_input|
        Yaparc::Seq.new(
          Yaparc::Literal.new('?'),
          Yaparc::Regex.new(/[a-zA-Z0-9]+/)
        ) do |_, var|
        end
      end
    end
  end

  class List
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |_input|
        Yaparc::Seq.new(
          Yaparc::Literal.new('['),
          Yaparc::Literal.new(']')
        )
      end
    end
  end
end
