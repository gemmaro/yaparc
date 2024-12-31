# frozen_string_literal: true

require 'test_helper'

# Metric Interchange Syntax
#
# c.f. http://people.csail.mit.edu/jaffer/MIXF/MIXF-08
# Here is a YACC-like syntax for metric quantities (with [ISO 6093] numbers).
#
#
#  quantity_value
#         : numerical_value
#         | numerical_value '.' unit
#         ;
#
#  unit
#         : unit_product
#         | unit_product '/' single_unit
#         ;
#
#  unit_product
#         : single_unit
#         | unit_product '.' single_unit
#         ;
#
#  single_unit
#         : punit
#         | punit '^' uxponent
#         | '(' unit ')'
#         | '(' unit ')^' uxponent
#         ;
#
#  uxponent
#         : uinteger
#         | '-' uinteger
#         | '(' uinteger '/' uinteger ')'
#         | '(-' uinteger '/' uinteger ')'
#         ;
#
#  punit
#         : decimal_multiple_prefix unit_p_symbol
#         | decimal_submultiple_prefix unit_n_symbol
#         | decimal_multiple_prefix unit_b_symbol
#         | decimal_submultiple_prefix unit_b_symbol
#         | binary_prefix 'B'
#         | binary_prefix 'bit'
#         | unit_p_symbol
#         | unit_n_symbol
#         | unit_b_symbol
#         | unit___symbol
#         ;
#
#  decimal_multiple_prefix
#         : 'E' | 'G' | 'M' | 'P' | 'T' | 'Y' | 'Z' | 'da' | 'h' | 'k'
#         ;
#
#  decimal_submultiple_prefix
#         : 'a' | 'c' | 'd' | 'f' | 'm' | 'n' | 'p' | 'u' | 'y' | 'z'
#         ;
#
#  binary_prefix
#         : 'Ei' | 'Gi' | 'Ki' | 'Mi' | 'Pi' | 'Ti'
#         ;
#
#  unit_p_symbol
#         : 'B' | 'Bd' | 'r' | 't'
#         ;
#
#  unit_n_symbol
#         : 'L' | 'Np' | 'o' | 'oC' | 'rad' | 'sr'
#         ;
#
#  unit_b_symbol
#         : 'A' | 'Bq' | 'C' | 'F' | 'Gy' | 'H' | 'Hz' | 'J' | 'K' | 'N'
#         | 'Ohm' | 'Pa' | 'S' | 'Sv' | 'T' | 'V' | 'W' | 'Wb' | 'bit'
#         | 'cd' | 'eV' | 'g' | 'kat' | 'lm' | 'lx' | 'm' | 'mol' | 's'
#         ;
#
#  unit___symbol
#         : 'd' | 'dB' | 'h' | 'min' | 'u'
#         ;
#
#  real
#         : ureal
#         | '-' ureal
#         ;
#
#  ureal
#         : numerical_value
#         | numerical_value suffix
#         ;
#
#  numerical_value
#         : uinteger
#         | dot uinteger
#         | uinteger dot uinteger
#         | uinteger dot
#         ;
#
#  dot
#         : '.' | ','
#         ;
#
#  uinteger
#         : digit uinteger
#         | uinteger
#         ;
#
#  suffix
#         : exponent_marker uinteger
#         | exponent_marker '-' uinteger
#         ;
#
#  exponent_marker
#         : 'e' | 'E'
#         ;
#
#  digit
#         : '0' | '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9'
#         ;
#

module MISParser
  #  quantity_value
  #         : numerical_value ['.' unit]*
  #         ;
  class QuantityValue
    include Yaparc::Parsable

    def initialize
      @parser = lambda do |_input|
        Yaparc::Seq.new(NumericalValue.new,
                        Yaparc::ZeroOne.new(
                          Yaparc::Seq.new(Yaparc::Literal.new('.'), Unit.new)
                        ))
      end
    end
  end

  #  unit
  #         : unit_product ['/' single_unit]*
  #         ;
  class Unit
    include Yaparc::Parsable

    def initialize
      @parser = lambda do |_input|
        Yaparc::Seq.new(UnitProduct.new,
                        Yaparc::ZeroOne.new(
                          Yaparc::Seq.new(Yaparc::Literal.new('/'), SingleUnit.new)
                        ))
      end
    end
  end

  #  unit_product
  #         : single_unit [unit_product '.' single_unit]*
  #         ;
  class UnitProduct
    include Yaparc::Parsable

    def initialize
      @parser = lambda do |_input|
        Yaparc::Seq.new(SingleUnit.new,
                        Yaparc::ZeroOne.new(
                          Yaparc::Seq.new(UnitProduct.new, Yaparc::Literal.new('.'), SingleUnit.new)
                        ))
      end
    end
  end

  #  single_unit
  #         : punit
  #         | punit '^' uxponent
  #         | '(' unit ')'
  #         | '(' unit ')^' uxponent
  #         ;
  class SingleUnit
    include Yaparc::Parsable

    def initialize
      @parser = lambda do |_input|
        Yaparc::Alt.new(
          Yaparc::Seq.new(Punit.new, Yaparc::Literal.new('^'), Uxponent.new),
          Punit.new,
          Yaparc::Seq.new(Yaparc::Literal.new('('), Unit.new, Yaparc::Literal.new(')^'), Uxponent.new),
          Yaparc::Seq.new(Yaparc::Literal.new('('), Unit.new, Yaparc::Literal.new(')'))
        )
      end
    end
  end

  #  uxponent
  #         : uinteger
  #         | '-' uinteger
  #         | '(' uinteger '/' uinteger ')'
  #         | '(-' uinteger '/' uinteger ')'
  #         ;
  class Uxponent
    include Yaparc::Parsable

    def initialize
      @parser = lambda do |_input|
        Yaparc::Alt.new(
          Uinteger.new,
          Yaparc::Seq.new(Yaparc::Literal.new('-'), Uinteger.new),
          Yaparc::Seq.new(Yaparc::Literal.new('('), Uinteger.new, Yaparc::Literal.new('/'), Uinteger.new,
                          Yaparc::Literal.new(')')),
          Yaparc::Seq.new(Yaparc::Literal.new('(-'), Uinteger.new, Yaparc::Literal.new('/'), Uinteger.new,
                          Yaparc::Literal.new(')'))
        )
      end
    end
  end

  #  punit
  #         : decimal_multiple_prefix unit_p_symbol
  #         | decimal_submultiple_prefix unit_n_symbol
  #         | decimal_multiple_prefix unit_b_symbol
  #         | decimal_submultiple_prefix unit_b_symbol
  #         | binary_prefix 'B'
  #         | binary_prefix 'bit'
  #         | unit_p_symbol
  #         | unit_n_symbol
  #         | unit_b_symbol
  #         | unit___symbol
  #         ;
  class Punit
    include Yaparc::Parsable

    def initialize
      @parser = lambda do |_input|
        Yaparc::Alt.new(
          Yaparc::Seq.new(DecimalMultiplePrefix.new, UnitPSymbol.new),
          Yaparc::Seq.new(DecimalSubmultiplePrefix.new, UnitNSymbol.new),
          Yaparc::Seq.new(DecimalMultiplePrefix.new, UnitBSymbol.new),
          Yaparc::Seq.new(DecimalSubmultiplePrefix.new, UnitBSymbol.new),
          Yaparc::Seq.new(BinaryPrefix.new, Yaparc::Literal.new('B')),
          Yaparc::Seq.new(BinaryPrefix.new, Yaparc::Literal.new('bit')),
          UnitPSymbol.new,
          UnitNSymbol.new,
          UnitBSymbol.new,
          UnitSymbol.new
        )
      end
    end
  end

  #  decimal_multiple_prefix
  class DecimalMultiplePrefix
    include Yaparc::Parsable

    def initialize
      @parser = lambda do |_input|
        Yaparc::Regex.new(/\AE|G|M|P|T|Y|Z|da|h|k/)
      end
    end
  end

  #  decimal_submultiple_prefix
  #         : 'a' | 'c' | 'd' | 'f' | 'm' | 'n' | 'p' | 'u' | 'y' | 'z'
  #         ;
  class DecimalSubmultiplePrefix
    include Yaparc::Parsable

    def initialize
      @parser = lambda do |_input|
        Yaparc::Regex.new(/\A[acdfmnpuyz]/)
      end
    end
  end

  #  binary_prefix
  #         : 'Ei' | 'Gi' | 'Ki' | 'Mi' | 'Pi' | 'Ti'
  #         ;
  class BinaryPrefix
    include Yaparc::Parsable

    def initialize
      @parser = lambda do |_input|
        Yaparc::Regex.new(/\AEi|Gi|Ki|Mi|Pi|Ti/)
      end
    end
  end

  #  unit_p_symbol
  #         : 'B' | 'Bd' | 'r' | 't'
  #         ;
  class UnitPSymbol
    include Yaparc::Parsable

    def initialize
      @parser = lambda do |_input|
        Yaparc::Regex.new(/\ABd|B|r|t/)
      end
    end
  end

  #  unit_n_symbol
  #         : 'L' | 'Np' | 'o' | 'oC' | 'rad' | 'sr'
  #         ;
  class UnitNSymbol
    include Yaparc::Parsable

    def initialize
      @parser = lambda do |_input|
        Yaparc::Regex.new(/\AL|Np|o|oC|rad|sr/)
      end
    end
  end

  #  unit_b_symbol
  #         : 'A' | 'Bq' | 'C' | 'F' | 'Gy' | 'H' | 'Hz' | 'J' | 'K' | 'N'
  #         | 'Ohm' | 'Pa' | 'S' | 'Sv' | 'T' | 'V' | 'W' | 'Wb' | 'bit'
  #         | 'cd' | 'eV' | 'g' | 'kat' | 'lm' | 'lx' | 'm' | 'mol' | 's'
  #         ;
  class UnitBSymbol
    include Yaparc::Parsable

    def initialize
      @parser = lambda do |_input|
        Yaparc::Regex.new(/\AA|Bq|C|F|Gy|H|Hz|J|K|N|Ohm|Pa|S|Sv|T|V|W|Wb|bit|cd|eV|g|kat|lm|lx|m|mol|s/)
      end
    end
  end

  #  unit___symbol
  #         : 'd' | 'dB' | 'h' | 'min' | 'u'
  #         ;
  class UnitSymbol
    include Yaparc::Parsable

    def initialize
      @parser = lambda do |_input|
        Yaparc::Regex.new(/\Ad|dB|h|min|u/)
      end
    end
  end

  #  real
  #         : ureal
  #         | '-' ureal
  #         ;
  class Real
    include Yaparc::Parsable

    def initialize
      @parser = lambda do |_input|
        Yaparc::Seq.new(Yaparc::ZeroOne.new(Yaparc::Literal.new('-'), ''), Ureal.new)
      end
    end
  end

  #  ureal
  #         : numerical_value
  #         | numerical_value suffix
  #         ;
  class Ureal
    include Yaparc::Parsable

    def initialize
      @parser = lambda do |_input|
        Yaparc::Seq.new(NumericalValue.new, Yaparc::ZeroOne.new(Suffix.new, ''))
      end
    end
  end

  #  numerical_value
  #         : uinteger
  #         | dot uinteger
  #         | uinteger dot uinteger
  #         | uinteger dot
  #         ;

  class NumericalValue
    include Yaparc::Parsable

    def initialize
      @parser = lambda do |_input|
        Yaparc::Alt.new(Uinteger.new,
                        Yaparc::Seq.new(Dot.new, Uinteger.new),
                        Yaparc::Seq.new(Uinteger.new, Dot.new, Yaparc::ZeroOne.new(Uinteger.new, '')))
      end
    end
  end

  #  dot
  #         : '.' | ','
  #         ;

  class Dot
    include Yaparc::Parsable

    def initialize
      @parser = lambda do |_input|
        Yaparc::Regex.new(/\A[.,]/)
      end
    end
  end

  #  suffix
  #         : exponent_marker uinteger
  #         | exponent_marker '-' uinteger
  #         ;

  class Suffix
    include Yaparc::Parsable

    def initialize
      @parser = lambda do |_input|
        Yaparc::Seq.new(ExponentMarker.new,
                        Yaparc::ZeroOne.new(Yaparc::Literal.new('-'), ''),
                        Uinteger.new)
      end
    end
  end

  #  uinteger
  #         : [digit]+
  #         ;
  class Uinteger
    include Yaparc::Parsable

    def initialize
      @parser = lambda do |_input|
        Yaparc::ManyOne.new(Digit.new, '')
      end
    end
  end

  #  exponent_marker
  #         : 'e' | 'E'
  #         ;

  class ExponentMarker
    include Yaparc::Parsable

    def initialize
      @parser = lambda do |_input|
        Yaparc::Regex.new(/\A[eE]/)
      end
    end
  end

  #  digit
  #         : '0' | '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9'
  #         ;

  class Digit
    include Yaparc::Parsable

    def initialize
      @parser = lambda do |_input|
        Yaparc::Regex.new(/\A\d/)
      end
    end
  end
end # of MISParser

class MISTest < Test::Unit::TestCase
  include ::Yaparc

  def test_digit
    digit = MISParser::Digit.new
    assert_instance_of OK, digit.parse('3')
  end

  def test_uinteger
    uinteger = MISParser::Digit.new
    assert_instance_of OK, uinteger.parse('3')
    assert_instance_of OK, uinteger.parse('123')
    assert_instance_of OK, uinteger.parse('0123')
  end

  def test_suffix
    suffix = MISParser::Suffix.new
    assert_instance_of OK, suffix.parse('e3')
    assert_instance_of OK, suffix.parse('E-10')
    assert_instance_of OK, suffix.parse('e09876')
  end

  def test_numerical_value
    numerical_value = MISParser::NumericalValue.new
    assert_instance_of OK, numerical_value.parse('3')
    assert_instance_of OK, numerical_value.parse('0.9')
    assert_instance_of OK, numerical_value.parse('.987')
    assert_instance_of OK, numerical_value.parse('0987.')
  end

  def test_ureal
    ureal = MISParser::Ureal.new
    assert_instance_of OK, ureal.parse('3')
    assert_instance_of OK, ureal.parse('0.9e10')
    assert_instance_of OK, ureal.parse('.987E-098')
  end

  def test_real
    real = MISParser::Real.new
    assert_instance_of OK, real.parse('-0.9e10')
    assert_instance_of OK, real.parse('-.987E-098')
  end

  def test_unit
    unit = MISParser::Unit.new
    assert_instance_of OK, unit.parse('s^-1')
    assert_instance_of OK, unit.parse('dm^3')
    assert_instance_of OK, unit.parse('rad^2')
    assert_instance_of OK, unit.parse('Mg')
    assert_instance_of OK, unit.parse('mol/s')
    assert_instance_of OK, unit.parse('cd.sr')
    assert_instance_of OK, unit.parse('lm/m^2')
    assert_instance_of OK, unit.parse('m.kg.s^-2')
    assert_instance_of OK, unit.parse('N/m^2')
    assert_instance_of OK, unit.parse('N.m')
    assert_instance_of OK, unit.parse('J/s')
    assert_instance_of OK, unit.parse('s.A')
    assert_instance_of OK, unit.parse('W/A')
    assert_instance_of OK, unit.parse('C/V')
    assert_instance_of OK, unit.parse('V/A')
    assert_instance_of OK, unit.parse('A/V')
    assert_instance_of OK, unit.parse('V.s')
    assert_instance_of OK, unit.parse('Wb/m^2')
    assert_instance_of OK, unit.parse('Wb/A')
    assert_instance_of OK, unit.parse('m^2.s^-2')
    assert_instance_of OK, unit.parse('m^2')
    assert_instance_of OK, unit.parse('m^3')
    assert_instance_of OK, unit.parse('m/s')
    assert_instance_of OK, unit.parse('m/s^2')
    assert_instance_of OK, unit.parse('m^-1')
    assert_instance_of OK, unit.parse('kg/m^3')
    assert_instance_of OK, unit.parse('m^3/kg')
    assert_instance_of OK, unit.parse('A/m^2')
    assert_instance_of OK, unit.parse('mol/m^3')
    assert_instance_of OK, unit.parse('cd/m^3')
    assert_instance_of OK, unit.parse('rad/s')
    assert_instance_of OK, unit.parse('rad/s^2')
    assert_instance_of OK, unit.parse('Pa.s')
    assert_instance_of OK, unit.parse('W/m^2')
    assert_instance_of OK, unit.parse('W/sr')
    assert_instance_of OK, unit.parse('W/(m^2.sr)')
    assert_instance_of OK, unit.parse('J/K')
    assert_instance_of OK, unit.parse('J/(kg.K)')
    assert_instance_of OK, unit.parse('J/kg')
    assert_instance_of OK, unit.parse('W/(m.k)')
    assert_instance_of OK, unit.parse('J/m^3')
    assert_instance_of OK, unit.parse('C/m^3')
    assert_instance_of OK, unit.parse('F/m')
    assert_instance_of OK, unit.parse('H/m')
    assert_instance_of OK, unit.parse('J/mol')
    assert_instance_of OK, unit.parse('J/(mol.k)')
    assert_instance_of OK, unit.parse('C/kg')
    assert_instance_of OK, unit.parse('r/min')
    assert_instance_of OK, unit.parse('kat/m^3')
    assert_instance_of OK, unit.parse('Mib/s')
    assert_instance_of OK, unit.parse('nV/Hz^(1/2)')
  end

  def test_quantity_value
    quantity_value = MISParser::QuantityValue.new
    assert_instance_of OK, quantity_value.parse('60.s')
    assert_instance_of OK, quantity_value.parse('60.min')
    assert_instance_of OK, quantity_value.parse('24.h')
    assert_instance_of OK, quantity_value.parse('6.283185307179586.rad')
    assert_instance_of OK, quantity_value.parse('2.777777777777778e-3.r')
    assert_instance_of OK, quantity_value.parse('8.bit')
    assert_instance_of OK, quantity_value.parse('1.660538782e-27.kg')
    assert_instance_of OK, quantity_value.parse('1.602176487e-19.J')
    assert_instance_of OK, quantity_value.parse('0.1151293.Np')
  end
end
