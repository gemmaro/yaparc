# frozen_string_literal: true

require 'test_helper'
require_relative "prolog_parser"

class PrologTest < Test::Unit::TestCase
  include ::Yaparc

  def test_variable
    var = PrologParser::Variable.new
    result = var.parse('?Var')
    assert_instance_of OK, result
    #    assert_equal LogRuby::Variable.new("Var"), result.value
  end

  def test_atom
    atom = PrologParser::Atom.new
    result = atom.parse('atom')
    assert_instance_of OK, result
    #    assert_equal LogRuby::Atom.new("atom"), result.value
  end

  def test_arglist
    arglist = PrologParser::ArgList.new
    result = arglist.parse('term1,term2,term3')
    assert_instance_of OK, result
    #    assert_equal LogRuby::Atom.new("atom"), result.value
  end

  def test_compoundterm
    compoundterm = PrologParser::CompoundTerm.new
    result = compoundterm.parse('functor(term1,term2,term3)')
    assert_instance_of OK, result
    #    assert_equal LogRuby::CompoundTerm.new(LogRuby::Atom.new("functor"),
    #                                           LogRuby::Atom.new("term1"),LogRuby::Atom.new("term2"),LogRuby::Atom.new("term3")), result.value
  end

  def test_query
    query = PrologParser::Query.new
    result = query.parse('?- functor(?var,term).')
    assert_instance_of OK, result
    #    assert_equal LogRuby::Query.new(LogRuby::CompoundTerm.new(LogRuby::Atom.new('functor'),LogRuby::Variable.new('var'), LogRuby::Atom.new('term'))), result.value
  end

  def test_fact
    fact = PrologParser::Fact.new
    result = fact.parse('functor(term).')
    assert_instance_of OK, result
    #    assert_equal LogRuby::Fact.new(LogRuby::CompoundTerm.new(LogRuby::Atom.new('functor'),LogRuby::Atom.new('term'))), result.value
  end

  def test_rule
    # likes(X, P) :- based(P,Y), likes(X,Y).
    rule_parser = PrologParser::Rule.new
    result = rule_parser.parse('likes(?X, ?P) :- based(?P,?Y), likes(?X,?Y).')
    assert_instance_of OK, result
    #    assert_equal rule, result.value
  end
end
