require 'test_helper'

=begin

<prog> ::= <clause> [ <clause> ]*
<clause> ::= <fact> | <rule> | <query>
	
<fact> ::= <compoundterm> . 	
<compoundterm> ::= <atom> [ ( <arglist> ) ]*
	
<rule> ::= <head> :- <body> .	
<query> ::= ?- <body> .	
<head> ::= <compoundterm> 	
<body> ::= <goal> [, <goal>]*	
<goal> ::= <compoundterm> | !
	
<arglist> := <arg>[, <arg>]*
<arg> ::= <atom> | <var> | <list>	
	
<atom> ::= /[a-zA-Z][a-zA-Z0-9]*/
         | '/[a-zA-Z0-9]+/'

<var> ::= ?/[a-zA-Z0-9]+/ 
	
<list> ::= <leftbracket> <rightbracket>	
<list> ::= <leftbracket> <listelems> <rightbracket> 	
<listelems> ::= <arglist>	
<listelems> ::= <arglist> <barsymbol> <list>	
<listelems> ::= <arglist> <barsymbol> <var>	
	
=end

module PrologParser
  #  KEYWORDS = %w{}
  # <prog> ::= <clause> [ <clause> ]*
  class Program
    include Yaparc::Parsable

    def initialize
      @parser = lambda do |input|
        Yaparc::Seq.new(Yaparc::ManyOne.new(Clause.new,[])) do |clauses|
          #LogRuby::Program.new(*clauses)
        end
      end
    end
  end

  # <clause> ::= <fact> | <rule> | <query>
  class Clause
    include Yaparc::Parsable
    def initialize

      @parser = lambda do |input|
        Yaparc::Alt.new(
                        PrologParser::Fact.new,
                        PrologParser::Rule.new,
                        PrologParser::Query.new
                        )
      end
    end
  end

  # <fact> ::= <compoundterm> .
  class Fact
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        Yaparc::Seq.new(
                        PrologParser::CompoundTerm.new,
                        Yaparc::Literal.new('.')) do |compoundterm,_|
          #LogRuby::Fact.new(compoundterm)
        end
      end
    end
  end

  # <compoundterm> ::= <atom> [ ( <arglist> ) ]*
  class CompoundTerm
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        Yaparc::Seq.new(
                        PrologParser::Atom.new,
                        Yaparc::ManyOne.new(
                                            Yaparc::Seq.new(
                                                            Yaparc::Literal.new('('),
                                                            PrologParser::ArgList.new,
                                                            Yaparc::Literal.new(')')) do |_,arglist,_|
                                              arglist
                                            end) do ||
                        end) do |head, tail|
          #LogRuby::CompoundTerm.new(head,*tail)
        end
      end
    end
  end


  # <rule> ::= <head> :- <body> .
  class Rule
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        Yaparc::Seq.new(
                        PrologParser::Head.new,
                        Yaparc::Literal.new(':-'),
                        PrologParser::Body.new,
                        Yaparc::Literal.new('.')) do |head,_,body,_|
          #LogRuby::Rule.new(head,*body)
        end
      end
    end
  end

  # <query> ::= ?- <body> .
  class Query
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        Yaparc::Seq.new(
                        Yaparc::Literal.new('?-'),
                        PrologParser::Body.new,
                        Yaparc::Literal.new('.')) do |_,body,_|
#          LogRuby::Query.new(*body)
        end
      end
    end
  end

  # <head> ::= <compoundterm>
  class Head
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        PrologParser::CompoundTerm.new
      end
    end
  end

  # <body> ::= <goal> [, <goal>]*
  class Body
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        Yaparc::ManyOne.new(PrologParser::Goal.new,[])
      end
    end
  end

  # <goal> ::= <compoundterm> | !
  class Goal
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        Yaparc::Alt.new(
                        PrologParser::CompoundTerm.new,
                        Yaparc::Literal.new('!'))
      end
    end
  end

  # <arglist> := <arg>[, <arg>]*
  class ArgList
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        Yaparc::Seq.new(
                        PrologParser::Arg.new,
                        Yaparc::Many.new(
                                         Yaparc::Seq.new(Yaparc::Literal.new(','), PrologParser::Arg.new),[])) do |head,tail|
          [head] + tail
        end
      end
    end
  end

  # <arg> ::= <atom> | <var> | <list>
  class Arg
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        Yaparc::Alt.new(
                        PrologParser::Variable.new,
                        PrologParser::Atom.new,
                        PrologParser::List.new)
      end
    end
  end

  # <atom> ::= /[a-zA-Z][a-zA-Z0-9]*/
  #          | '/[a-zA-Z0-9]+/'
  class Atom
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        Yaparc::Seq.new(Yaparc::Regex.new(/[a-zA-Z][a-zA-Z0-9]*/)) do |ide|
          #LogRuby::Atom.new(ide)
        end
      end
    end
  end

  # <var> ::= ?/[a-zA-Z0-9]+/
  class Variable
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        Yaparc::Seq.new(
                        Yaparc::Literal.new("?"),
                        Yaparc::Regex.new(/[a-zA-Z0-9]+/)) do |_,var|
#          LogRuby::Variable.new(var)
        end
      end
    end
  end

  # <list> ::= <leftbracket> <rightbracket>
  class List
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        Yaparc::Seq.new(
                        Yaparc::Literal.new("["),
                        Yaparc::Literal.new("]"))
      end
    end
  end
end # of PrologParser


class PrologTest < Test::Unit::TestCase
  include ::Yaparc


  def test_variable
    var = PrologParser::Variable.new
    result = var.parse("?Var")
    assert_instance_of Result::OK, result
#    assert_equal LogRuby::Variable.new("Var"), result.value
  end

  def test_atom
    atom = PrologParser::Atom.new
    result = atom.parse("atom")
    assert_instance_of Result::OK, result
#    assert_equal LogRuby::Atom.new("atom"), result.value
  end

  def test_arglist
    arglist = PrologParser::ArgList.new
    result = arglist.parse("term1,term2,term3")
    assert_instance_of Result::OK, result
#    assert_equal LogRuby::Atom.new("atom"), result.value
  end

  def test_compoundterm
    compoundterm = PrologParser::CompoundTerm.new
    result = compoundterm.parse("functor(term1,term2,term3)")
    assert_instance_of Result::OK, result
#    assert_equal LogRuby::CompoundTerm.new(LogRuby::Atom.new("functor"),
#                                           LogRuby::Atom.new("term1"),LogRuby::Atom.new("term2"),LogRuby::Atom.new("term3")), result.value
  end

  def test_query
    query = PrologParser::Query.new
    result = query.parse("?- functor(?var,term).")
    assert_instance_of Result::OK, result
#    assert_equal LogRuby::Query.new(LogRuby::CompoundTerm.new(LogRuby::Atom.new('functor'),LogRuby::Variable.new('var'), LogRuby::Atom.new('term'))), result.value
  end

  def test_fact
    fact = PrologParser::Fact.new
    result = fact.parse("functor(term).")
    assert_instance_of Result::OK, result
#    assert_equal LogRuby::Fact.new(LogRuby::CompoundTerm.new(LogRuby::Atom.new('functor'),LogRuby::Atom.new('term'))), result.value
  end

  def test_rule
    # likes(X, P) :- based(P,Y), likes(X,Y).
    rule_parser = PrologParser::Rule.new
    result = rule_parser.parse("likes(?X, ?P) :- based(?P,?Y), likes(?X,?Y).")
    assert_instance_of Result::OK, result
#    assert_equal rule, result.value
  end

end
