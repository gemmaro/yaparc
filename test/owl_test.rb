# frozen_string_literal: true

require 'test_helper'
require_relative "owl_parser"

class OwlTest < Test::Unit::TestCase
  include ::Yaparc

  def test_ontology
    ontology = OWLParser::Ontology.new
    result = ontology.parse('Ontology()')
    assert_instance_of OK, result
    result = ontology.parse('Ontology(ex:ontology_id)')
    assert_instance_of OK, result
    result = ontology.parse('Ontology(Class(ex:class complete annotation(ex:annotation http://localhost.localdomain )))')
    assert_instance_of OK, result
    result = ontology.parse('Ontology(Class(ex:class Deprecated partial annotation(ex:annotation http://localhost.localdomain )))')
    assert_instance_of OK, result

    ontology1 = <<-EOS
     Ontology(ontology1
       Class(Pc complete unionOf(Desktop Laptop))
       Individual(ibmR40 type(Laptop))
       Individual(compaqPresario200 type(Desktop))
       Class(PcOffice complete intersectionOf(Pc complementOf(Desktop))))
    EOS
    result = ontology.parse(ontology1)
    assert_instance_of OK, result
  end

  def test_directive
    directive = OWLParser::Directive.new
    result = directive.parse('Class(ex:class complete )')
    assert_instance_of OK, result
    result = directive.parse('Class(ex:class complete annotation(ex:annotation http://localhost.localdomain ))')
    assert_instance_of OK, result
    result = directive.parse('Class(ex:class Deprecated partial annotation(ex:annotation http://localhost.localdomain ))')
    assert_instance_of OK, result
  end

  def test_axiom
    axiom = OWLParser::Axiom.new
    result = axiom.parse('Class(Pc complete unionOf(Desktop Laptop))')
    assert_instance_of OK, result
    result = axiom.parse('Class(ex:class_id complete )')
    assert_instance_of OK, result
    result = axiom.parse('EnumeratedClass(ex:class_id Deprecated )')
    assert_instance_of OK, result
    result = axiom.parse('Class(ex:class complete annotation(ex:annotation http://localhost.localdomain ))')
    assert_instance_of OK, result
    result = axiom.parse('Class(ex:class Deprecated partial annotation(ex:annotation http://localhost.localdomain ))')
    result = axiom.parse('SubClassOf(ex:subclass ex:superclass)')
    assert_instance_of OK, result
  end

  def test_annotation
    annotation = OWLParser::Annotation.new
    result = annotation.parse('annotation(ex:annotation http://localhost.localdomain)')
    assert_instance_of OK, result
    result = annotation.parse('annotation(ex:annotation type(ex:human))')
    assert_instance_of Fail, result
    result = annotation.parse('annotation(ex:annotation "akimichi"^^http://www.w3.org/2001/XMLSchema@integer)')
    assert_instance_of OK, result
    assert_instance_of Fail, annotation.parse('annotation(ex:annotation value(ex:human))')
    assert_instance_of Fail, annotation.parse('annotation(ex:annotation type(ex:human) value(ex:human))')
  end

  def test_value
    value = OWLParser::Value.new
    result = value.parse('value(ex:value http://localhost.localdomain)')
    assert_instance_of OK, result
  end

  def test_individual
    individual = OWLParser::Individual.new
    result = individual.parse('Individual(ex:individual)')
    assert_instance_of OK, result
    assert_equal Hash[individual_id: { uri_reference: 'ex:individual' }], result.value
    result = individual.parse('Individual(ex:individual type(ex:human))')
    assert_instance_of OK, result
    assert_instance_of OK, individual.parse('Individual(ex:individual type(ex:human))')
    assert_instance_of OK, individual.parse('Individual(ex:individual value(ex:human http://localhost.localdomain))')
    assert_instance_of OK, individual.parse('Individual(ex:individual type(ex:human) value(ex:human http://localhost.localdomain))')
  end

  def test_type
    type = OWLParser::Type.new
    assert_instance_of OK, type.parse('http://localhost.localdomain')
    assert_instance_of OK, type.parse('unionOf(  )')
    assert_instance_of OK, type.parse('unionOf(Desktop Laptop)')
    assert_instance_of OK, type.parse('unionOf(http://localhost.localdomain)')
    assert_instance_of OK, type.parse('ex:hasMember')
    assert_instance_of OK, type.parse('unionOf(ex:hasMember)')
    assert_instance_of OK, type.parse('intersectionOf(ex:hasMember)')
    assert_instance_of OK, type.parse('complementOf(intersectionOf(ex:hasMember))')
    assert_instance_of OK, type.parse('oneOf(ex:hasMember)')
  end

  def test_description
    description = OWLParser::Description.new
    assert_instance_of OK, description.parse('http://localhost.localdomain')
    assert_instance_of OK, description.parse('unionOf(  )')
    assert_instance_of OK, description.parse('unionOf(http://localhost.localdomain)')
    assert_instance_of OK, description.parse('unionOf(Desktop Laptop)')
    assert_instance_of OK, description.parse('ex:hasMember')
    assert_instance_of OK, description.parse('unionOf(ex:hasMember)')
    assert_instance_of OK, description.parse('intersectionOf(ex:hasMember)')
    assert_instance_of OK, description.parse('complementOf(intersectionOf(ex:hasMember))')
    assert_instance_of OK, description.parse('oneOf(ex:hasMember)')
    assert_instance_of OK, description.parse('restriction(ex:hasMember allValuesFrom(ex:StringPlayer))')
  end

  def test_individual_restriction_component
    individual_restriction_component = OWLParser::IndividualRestrictionComponent.new
    result = individual_restriction_component.parse('allValuesFrom(ex:StringPlayer)')
    assert_instance_of OK, result
    assert_equal '', result.input
    result = individual_restriction_component.parse('someValuesFrom(ex:StringPlayer)')
    assert_instance_of OK, result
    assert_equal '', result.input
    result = individual_restriction_component.parse('value(ex:StringPlayer)')
    assert_instance_of OK, result
    assert_equal '', result.input
    result = individual_restriction_component.parse('minCardinality(1)')
    assert_instance_of OK, result
    assert_equal '', result.input
  end

  def test_restriction
    restriction = OWLParser::Restriction.new
    assert_instance_of OK, restriction.parse('restriction(ex:hasMember value(datatype))')
    assert_instance_of OK, restriction.parse('restriction(ex:hasMember allValuesFrom(ex:StringPlayer))')
  end

  def test_data_restriction_component
    data_restriction_component = OWLParser::DataRestrictionComponent.new
    assert_instance_of OK, data_restriction_component.parse('value("akimichi"@ja)')
    assert_instance_of OK, data_restriction_component.parse('allValuesFrom( rdfs:Literal )')
    assert_instance_of OK, data_restriction_component.parse('allValuesFrom(ex:StringPlayer)')
    assert_instance_of OK, data_restriction_component.parse('allValuesFrom(http://localhost.localdomain)')
    assert_instance_of OK, data_restriction_component.parse('allValuesFrom(oneOf())')
    assert_instance_of OK, data_restriction_component.parse('allValuesFrom(oneOf("akimichi"@ja))')
    assert_instance_of OK, data_restriction_component.parse('maxCardinality(10)')
    assert_instance_of OK, data_restriction_component.parse('cardinality(398)')
    assert_instance_of OK, data_restriction_component.parse('minCardinality(1)')
    assert_instance_of OK, data_restriction_component.parse('maxCardinality(10)')
    assert_instance_of OK, data_restriction_component.parse('cardinality(398)')
  end

  def test_cardinality
    cardinality = OWLParser::Cardinality.new
    assert_instance_of OK, cardinality.parse('minCardinality(1)')
    assert_instance_of OK, cardinality.parse('maxCardinality(10)')
    assert_instance_of OK, cardinality.parse('cardinality(398)')
  end

  def test_data_range
    data_range = OWLParser::DataRange.new
    assert_instance_of OK, data_range.parse('datatype@localhost.localdomain')
    assert_instance_of OK, data_range.parse('http://datatype@localhost.localdomain')
    assert_instance_of OK, data_range.parse('http://localhost.localdomain')
    assert_instance_of OK, data_range.parse('datatype@localhost.localdomain)')
    assert_instance_of OK, data_range.parse('rdfs:Literal')
    assert_instance_of OK, data_range.parse('oneOf()')
    assert_instance_of OK, data_range.parse('oneOf("akimichi"@ja)')
    #    assert_instance_of OK, data_range.parse("oneOf( emile@datarange.localdomain )")
  end

  def test_data_literal
    data_literal = OWLParser::DataLiteral.new
    assert_instance_of OK, data_literal.parse('"akimichi"@ja')
    assert_instance_of OK, data_literal.parse('"akimichi"^^http://www.w3.org/2001/XMLSchema@integer')
    assert_instance_of Fail, data_literal.parse('ex:hasMember')
    assert_instance_of Fail, data_literal.parse('datatype')
    assert_instance_of Fail, data_literal.parse('emile@localhost.localdomain')
  end

  def test_plain_literal
    plain_literal = OWLParser::PlainLiteral.new
    assert_instance_of OK, plain_literal.parse('"akimichi"@ja')
    result = plain_literal.parse('"nick"@en-US')
    assert_instance_of OK, result
    assert_equal ['"nick"@en-US'], result.value
    assert_instance_of OK, plain_literal.parse('"akimichi"')
  end

  def test_typed_literal
    typed_literal = OWLParser::TypedLiteral.new
    assert_instance_of OK, typed_literal.parse('"akimichi"^^http://www.w3.org/2001/XMLSchema@integer')
  end

  def test_lexical_form
    lexical_form = OWLParser::LexicalForm.new
    assert_instance_of OK, lexical_form.parse('"ex:hasMember"')
    assert_instance_of OK, lexical_form.parse('"datatype"')
    assert_instance_of OK, lexical_form.parse('"emile@localhost.localdomain"')
  end

  def test_language_tag
    language_tag = OWLParser::LanguageTag.new
    assert_instance_of OK, language_tag.parse('ja')
    result = language_tag.parse('en-US')
    assert_instance_of OK, result
    assert_equal 'en-US', result.value
  end

  def test_annotation_property_id
    annotation_property_id = OWLParser::AnnotationPropertyID.new
    result = annotation_property_id.parse('ex:annotation')
    assert_instance_of OK, result
    assert_equal Hash[annotation_property_id: { uri_reference: 'ex:annotation' }], result.value
  end

  def test_individual_id
    individual_id = OWLParser::IndividualID.new
    assert_instance_of Fail, individual_id.parse('type(')
    result = individual_id.parse('ex:individual')
    assert_instance_of OK, result
    assert_equal '', result.input
    result = individual_id.parse('ex:individual type')
    assert_instance_of OK, result
    assert_equal Hash[individual_id: { uri_reference: 'ex:individual' }], result.value
    assert_equal 'type', result.input
    assert_instance_of OK, individual_id.parse('http://localhost.localdomain:3000/pchar;param?query')
    assert_instance_of OK, individual_id.parse('http://localhost.localdomain')
  end

  def test_ontology_id
    ontology_id = OWLParser::OntologyID.new
    assert_instance_of OK, ontology_id.parse('http://localhost.localdomain:3000')
    result = ontology_id.parse('ex:individual type')
    assert_instance_of OK, result
  end

  def test_class_id
    class_id = OWLParser::ClassID.new
    result = class_id.parse('ex:class_id')
    assert_instance_of OK, result
    assert_equal Hash[class_id: { uri_reference: 'ex:class_id' }], result.value
    result = class_id.parse('ex:individual')
    assert_instance_of OK, class_id.parse('http://localhost.localdomain:3000')
    result = class_id.parse('ex:individual type')
    assert_instance_of OK, result
    assert_equal Hash[class_id: { uri_reference: 'ex:individual' }], result.value
    assert_equal 'type', result.input
    assert_instance_of OK, class_id.parse('http://localhost.localdomain:3000/pchar;param?query')
    assert_instance_of OK, class_id.parse('http://localhost.localdomain')
  end

  def test_uri_reference
    uri_reference = OWLParser::URIReference.new
    assert_instance_of OK, uri_reference.parse('http://localhost.localdomain:3000/pchar;param?query')
    assert_instance_of OK, uri_reference.parse('http://localhost.localdomain')
    result = uri_reference.parse('http://localhost.localdomain')
    assert_instance_of OK, result
    assert_equal Hash[uri_reference: 'http://localhost.localdomain'], result.value
    assert_equal '', result.input
    result = uri_reference.parse('http://localhost.localdomain)')
    assert_instance_of OK, result
    assert_equal Hash[uri_reference: 'http://localhost.localdomain'], result.value
    assert_equal ')', result.input
    result = uri_reference.parse('ex:hasMember')
    assert_instance_of OK, result
    assert_equal Hash[uri_reference: 'ex:hasMember'], result.value
    assert_equal '', result.input
    result = uri_reference.parse('')
    assert_instance_of Fail, result
  end
end
