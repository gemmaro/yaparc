# frozen_string_literal: true

require 'test_helper'
require_relative "mis_parser"

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
