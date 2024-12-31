module OWLParser
  KEYWORDS = %w[Ontology( Class( EnumeratedClass( DisjointClasses( EquivalentClasses( SubClassOf( Datatype(
                DatatypeProperty( ObjectProperty( AnnotationProperty( OntologyProperty( EquivalentProperties( SubPropertyOf( EquivalentProperties( type( Annotation( Individual( value( unionOf( intersectionOf( complementOf( oneOf( restriction( allValuesFrom( someValuesFrom( (minCardinality( maxCardinality( cardinality( rdfs:Literal]

  class Ontology
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |_input|
        Yaparc::Seq.new(Yaparc::Literal.new('Ontology('),
                        Yaparc::ZeroOne.new(OntologyID.new, {}),
                        Yaparc::Many.new(Directive.new, {}),
                        Yaparc::Literal.new(')')) do |_, ontologyID, directive, _|
          { ontologyID:, directive: }
        end
      end
    end
  end

  class Directive
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |_input|
        Yaparc::Alt.new(Yaparc::Seq.new(Yaparc::Literal.new('Annotation('),
                                        OntologyPropertyID.new,
                                        OntologyID.new,
                                        Yaparc::Literal.new(')')) do |_, ontology_property_id, ontology_id, _|
                          { ontology_property_id:, ontology_id: }
                        end,
                        Yaparc::Seq.new(Yaparc::Literal.new('Annotation('),
                                        AnnotationPropertyID.new,
                                        Yaparc::Alt.new(URIReference.new,
                                                        DataLiteral.new,
                                                        Individual.new),
                                        Yaparc::Literal.new(')')),
                        Axiom.new,
                        Fact.new)
      end
    end
  end

  class Axiom
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |_input|
        Yaparc::Alt.new(
          Yaparc::Seq.new(Yaparc::Literal.new('Class('),
                          ClassID.new,
                          Yaparc::ZeroOne.new(Yaparc::Literal.new('Deprecated'), {}),
                          Modality.new,
                          Yaparc::Many.new(Annotation.new, {}),
                          Yaparc::Many.new(Description.new, {}),
                          Yaparc::Literal.new(')')) do |_, class_id, deprecated, modality, annotations, descriptions, _|
            { class: { class_id:, deprecated:, modality:,
                       annotations:, descriptions: } }
          end,
          Yaparc::Seq.new(Yaparc::Literal.new('EnumeratedClass('),
                          ClassID.new,
                          Yaparc::ZeroOne.new(Yaparc::Literal.new('Deprecated'), {}),
                          Yaparc::Many.new(Annotation.new, {}),
                          Yaparc::Many.new(IndividualID.new, {}),
                          Yaparc::Literal.new(')')) do |_, class_id, deprecated, annotations, individual_ids, _|
            { enumerated_class: { class_id:, deprecated:,
                                  annotations:, individual_ids: } }
          end,
          Yaparc::Seq.new(Yaparc::Literal.new('DisjointClasses('),
                          Description.new,
                          Yaparc::ManyOne.new(Description.new, {}),
                          Yaparc::Literal.new(')')) do |_, description, descriptions, _|
            { disjoint_classes: description.merge(descriptions) }
          end,
          Yaparc::Seq.new(Yaparc::Literal.new('EquivalentClasses('),
                          Yaparc::ManyOne.new(Description.new, {}),
                          Yaparc::Literal.new(')')) do |_, descriptions, _|
            { equivalent_classes: descriptions }
          end,
          Yaparc::Seq.new(Yaparc::Literal.new('SubClassOf('),
                          Description.new,
                          Description.new,
                          Yaparc::Literal.new(')')) do |_, description1, description2, _|
            { sub_class_of: description1.merge(description2) }
          end,
          Yaparc::Seq.new(Yaparc::Literal.new('Datatype('),
                          DatatypeID.new,
                          Yaparc::ZeroOne.new(Yaparc::Literal.new('Deprecated'), {}),
                          Yaparc::Many.new(Annotation.new, {}),
                          Yaparc::Literal.new(')')) do |_, datatype_id, _, annotations, _|
            { datatype: { datatype_id:, annotations: } }
          end,
          Yaparc::Seq.new(Yaparc::Literal.new('DatatypeProperty('),
                          DatavaluedPropertyID.new,
                          Yaparc::ZeroOne.new(Yaparc::Literal.new('Deprecated'), {}),
                          Yaparc::Many.new(Annotation.new, {}),
                          Yaparc::Many.new(
                            Yaparc::Seq.new(Yaparc::Literal.new('super('),
                                            DatavaluedPropertyID.new,
                                            Yaparc::Literal.new(')')), {}
                          ),
                          Yaparc::ZeroOne.new(Yaparc::Literal.new('Functional'), {}),
                          Yaparc::Many.new(
                            Yaparc::Seq.new(Yaparc::Literal.new('domain('),
                                            Description.new,
                                            Yaparc::Literal.new(')')), {}
                          ),
                          Yaparc::Many.new(
                            Yaparc::Seq.new(Yaparc::Literal.new('range('),
                                            DataRange.new,
                                            Yaparc::Literal.new(')')), {}
                          ),
                          Yaparc::Literal.new(')')) do |_, _datavalued_property_id, _, annotation, super_tag, functional, domain, range, _|
            { datatype_property_id: { annotation:, super_tag:,
                                      functional:, domain:, range: } }
          end,
          Yaparc::Seq.new(Yaparc::Literal.new('ObjectProperty('),
                          IndividualvaluedPropertyID.new,
                          Yaparc::ZeroOne.new(Yaparc::Literal.new('Deprecated'), {}),
                          Yaparc::Many.new(Annotation.new, {}),
                          Yaparc::Many.new(
                            Yaparc::Seq.new(Yaparc::Literal.new('super('),
                                            IndividualvaluedPropertyID.new,
                                            Yaparc::Literal.new(')')), {}
                          ),
                          Yaparc::Many.new(
                            Yaparc::Seq.new(Yaparc::Literal.new('inverseOf('),
                                            IndividualvaluedPropertyID.new,
                                            Yaparc::Literal.new(')')), {}
                          ),
                          Yaparc::ZeroOne.new(Yaparc::Literal.new('Symmetric'), {}),
                          Yaparc::Alt.new(
                            Yaparc::Literal.new('Functional'),
                            Yaparc::Literal.new('InverseFunctional'),
                            Yaparc::Seq.new(Yaparc::Literal.new('Functional'),
                                            Yaparc::Literal.new('InverseFunctional')),
                            Yaparc::Literal.new('Transitive')
                          ),
                          Yaparc::Many.new(
                            Yaparc::Seq.new(Yaparc::Literal.new('domain('),
                                            Description.new,
                                            Yaparc::Literal.new(')')), {}
                          ),
                          Yaparc::Many.new(
                            Yaparc::Seq.new(Yaparc::Literal.new('range('),
                                            Description.new,
                                            Yaparc::Literal.new(')')), {}
                          ),
                          Yaparc::Literal.new(')')) do |_, _individualvaluedPropertyID1, _deprecated, _annotation, _super_tag, _inverseOf, _symmetric, _functional, _domain, _range, _|
            { object_property: {} }
          end,
          Yaparc::Seq.new(Yaparc::Literal.new('AnnotationPropertyID('),
                          AnnotationPropertyID.new,
                          Yaparc::ManyOne.new(Annotation.new, {}),
                          Yaparc::Literal.new(')')) do |_, annotationPropertyID, annotation, _|
            { annotationProperty: { annotationPropertyID:,
                                    annotation: } }
          end,
          Yaparc::Seq.new(Yaparc::Literal.new('OntologyProperty('),
                          OntologyPropertyID.new,
                          Yaparc::ManyOne.new(Annotation.new, {}),
                          Yaparc::Literal.new(')')) do |_, ontologyPropertyID, annotation, _|
            { OntologyProperty: { ontologyPropertyID:,
                                  annotation: } }
          end,
          Yaparc::Seq.new(Yaparc::Literal.new('EquivalentProperties('),
                          DatavaluedPropertyID.new,
                          Yaparc::ManyOne.new(DatavaluedPropertyID.new, {}),
                          Yaparc::Literal.new(')')) do |_, _datavaluedPropertyID, _datavaluedPropertyIDs, _|
            { equivalentProperties: {} }
          end,
          Yaparc::Seq.new(Yaparc::Literal.new('SubPropertyOf('),
                          DatavaluedPropertyID.new,
                          DatavaluedPropertyID.new,
                          Yaparc::Literal.new(')')) do |_, _datavaluedPropertyID1, _datavaluedPropertyID2, _|
            { subPropertyOf: {} }
          end,
          Yaparc::Seq.new(Yaparc::Literal.new('EquivalentProperties('),
                          IndividualvaluedPropertyID.new,
                          Yaparc::ManyOne.new(IndividualvaluedPropertyID.new, {}),
                          Yaparc::Literal.new(')')) do |_, _individualvaluedPropertyID, _individualvaluedPropertyIDs, _|
            { equivalentProperties: {} }
          end,
          Yaparc::Seq.new(Yaparc::Literal.new('SubPropertyOf('),
                          IndividualvaluedPropertyID.new,
                          IndividualvaluedPropertyID.new,
                          Yaparc::Literal.new(')')) do |_, _individualvaluedPropertyID1, _individualvaluedPropertyID2, _|
            { subPropertyOf: {} }
          end
        )
      end
    end
  end

  class Fact
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |_input|
        Individual.new
      end
    end
  end

  class Individual
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |_input|
        Yaparc::Seq.new(Yaparc::Literal.new('Individual('),
                        Yaparc::ZeroOne.new(IndividualID.new, {}),
                        Yaparc::Many.new(Annotation.new, {}),
                        Yaparc::Many.new(
                          Yaparc::Seq.new(Yaparc::Literal.new('type('),
                                          Type.new,
                                          Yaparc::Literal.new(')')) do |_, type, _|
                            { type: }
                          end, {}
                        ),
                        Yaparc::Many.new(Value.new, {}),
                        Yaparc::Literal.new(')')) do |_, individual_id, annotations, types, values, _|
          individual_id.merge(annotations).merge(types).merge(values)
        end
      end
    end
  end

  class Annotation
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |_input|
        Yaparc::Alt.new(Yaparc::Seq.new(Yaparc::Literal.new('annotation('),
                                        AnnotationPropertyID.new,
                                        URIReference.new,
                                        Yaparc::Literal.new(')')) do |_, annotation_property_id, uri_reference, _|
                          { annotation_property_id:, uri_reference: }
                        end,
                        Yaparc::Seq.new(Yaparc::Literal.new('annotation('),
                                        AnnotationPropertyID.new,
                                        DataLiteral.new,
                                        Yaparc::Literal.new(')')) do |_, annotation_property_id, data_literal, _|
                          { annotation_property_id:, data_literal: }
                        end,
                        Yaparc::Seq.new(Yaparc::Literal.new('annotation('),
                                        AnnotationPropertyID.new,
                                        Individual.new,
                                        Yaparc::Literal.new(')')) do |_, annotation_property_id, individual, _|
                          { annotation_property_id:, individual: }
                        end)
      end
    end
  end

  class Value
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |_input|
        Yaparc::Alt.new(Yaparc::Seq.new(Yaparc::Literal.new('value('),
                                        IndividualvaluedPropertyID.new,
                                        IndividualID.new,
                                        Yaparc::Literal.new(')')) do |_, individualvalued_property_id, individual_id, _|
                          { individualvalued_property_id:,
                            individual_id: }
                        end,
                        Yaparc::Seq.new(Yaparc::Literal.new('value('),
                                        IndividualvaluedPropertyID.new,
                                        Individual.new,
                                        Yaparc::Literal.new(')')) do |_, individualvalued_property_id, individual, _|
                          { individualvalued_property_id:, individual: }
                        end,
                        Yaparc::Seq.new(Yaparc::Literal.new('value('),
                                        IndividualvaluedPropertyID.new,
                                        DataLiteral.new,
                                        Yaparc::Literal.new(')')) do |_, individualvalued_property_id, data_literal, _|
                          { individualvalued_property_id:,
                            data_literal: }
                        end)
      end
    end
  end

  class Type
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |_input|
        Description.new
      end
    end
  end

  class Description
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |_input|
        Yaparc::Alt.new(Restriction.new,
                        Yaparc::Seq.new(Yaparc::Literal.new('unionOf('),
                                        Yaparc::Many.new(Description.new, {}),
                                        Yaparc::Literal.new(')')) do |_, description, _|
                          { unionOf: description }
                        end,
                        Yaparc::Seq.new(Yaparc::Literal.new('intersectionOf('),
                                        Yaparc::Many.new(Description.new, {}),
                                        Yaparc::Literal.new(')')) do |_, description, _|
                          { intersectionOf: description }
                        end,
                        Yaparc::Seq.new(Yaparc::Literal.new('complementOf('),
                                        Description.new,
                                        Yaparc::Literal.new(')')) do |_, description, _|
                          { complementOf: description }
                        end,
                        Yaparc::Seq.new(Yaparc::Literal.new('oneOf('),
                                        Yaparc::Many.new(IndividualID.new, {}),
                                        Yaparc::Literal.new(')')) do |_, description, _|
                          { oneOf: { individual_id: description } }
                        end,
                        ClassID.new)
      end
    end
  end

  class Restriction
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |_input|
        Yaparc::Alt.new(Yaparc::Seq.new(Yaparc::Literal.new('restriction('),
                                        DatavaluedPropertyID.new,
                                        Yaparc::ManyOne.new(DataRestrictionComponent.new, {}),
                                        Yaparc::Literal.new(')')) do |_, datavalued_property_id, data_restriction_components, _|
                          { datavalued_property_id:,
                            data_restriction_components: }
                        end,
                        Yaparc::Seq.new(Yaparc::Literal.new('restriction('),
                                        IndividualvaluedPropertyID.new,
                                        Yaparc::ManyOne.new(IndividualRestrictionComponent.new, {}),
                                        Yaparc::Literal.new(')')) do |_, individualvalued_property_id, individual_restriction_components, _|
                          { individualvalued_property_id:,
                            individual_restriction_components: }
                        end)
      end
    end
  end

  class IndividualRestrictionComponent
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |_input|
        Yaparc::Alt.new(Yaparc::Seq.new(Yaparc::Literal.new('allValuesFrom('),
                                        Description.new,
                                        Yaparc::Literal.new(')')) do |_, description, _|
                          { allValuesFrom: description }
                        end,
                        Yaparc::Seq.new(Yaparc::Literal.new('someValuesFrom('),
                                        Description.new,
                                        Yaparc::Literal.new(')')) do |_, description, _|
                          { someValuesFrom: description }
                        end,
                        Yaparc::Seq.new(Yaparc::Literal.new('value('),
                                        IndividualID.new,
                                        Yaparc::Literal.new(')')) do |_, individual_id, _|
                          { value: individual_id }
                        end,
                        Cardinality.new)
      end
    end
  end

  class Modality
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |_input|
        Yaparc::Alt.new(Yaparc::Literal.new('complete'), Yaparc::Literal.new('partial'))
      end
    end
  end

  class DataRestrictionComponent
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |_input|
        Yaparc::Alt.new(Yaparc::Seq.new(Yaparc::Literal.new('allValuesFrom('),
                                        DataRange.new,
                                        Yaparc::Literal.new(')')) do |_, data_range, _|
                          { allValuesFrom: data_range }
                        end,
                        Yaparc::Seq.new(Yaparc::Literal.new('someValuesFrom('),
                                        DataRange.new,
                                        Yaparc::Literal.new(')')) do |_, data_range, _|
                          { someValuesFrom: data_range }
                        end,
                        Yaparc::Seq.new(Yaparc::Literal.new('value('),
                                        DataLiteral.new,
                                        Yaparc::Literal.new(')')) do |_, data_literal, _|
                          { value: data_literal }
                        end,
                        Cardinality.new)
      end
    end
  end

  class Cardinality
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |_input|
        Yaparc::Alt.new(Yaparc::Seq.new(Yaparc::Literal.new('minCardinality('),
                                        Yaparc::Many.new(NonNegativeInteger.new, 0),
                                        Yaparc::Literal.new(')')) do |_, integer, _|
                          { minCardinality: integer }
                        end,
                        Yaparc::Seq.new(Yaparc::Literal.new('maxCardinality('),
                                        Yaparc::Many.new(NonNegativeInteger.new, 0),
                                        Yaparc::Literal.new(')')) do |_, integer, _|
                          { maxCardinality: integer }
                        end,
                        Yaparc::Seq.new(Yaparc::Literal.new('cardinality('),
                                        Yaparc::Many.new(NonNegativeInteger.new, 0),
                                        Yaparc::Literal.new(')')) do |_, integer, _|
                          { cardinality: integer }
                        end)
      end
    end
  end

  class NonNegativeInteger
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |_input|
        Yaparc::Apply.new(Yaparc::Regex.new(/\A[0-9]+/)) do |number|
          Integer(number)
        end
      end
    end
  end

  class DataRange
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |_input|
        Yaparc::Alt.new(Yaparc::Literal.new('rdfs:Literal'),
                        Yaparc::Seq.new(Yaparc::Literal.new('oneOf('),
                                        Yaparc::Many.new(DataLiteral.new, []),
                                        Yaparc::Literal.new(')')) do |_, data_literals, _|
                          { oneOf: data_literals }
                        end,
                        DatatypeID.new)
      end
    end
  end

  class OntologyID
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |_input|
        Yaparc::Apply.new(URIReference.new) do |uri|
          { ontology_id: uri }
        end
      end
    end
  end

  class DatavaluedPropertyID
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |_input|
        Yaparc::Apply.new(URIReference.new) do |uri|
          { datavalued_property_id: { uri_reference: uri } }
        end
      end
    end
  end

  class IndividualvaluedPropertyID
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |_input|
        Yaparc::Apply.new(URIReference.new) do |uri|
          { individualvalued_property_id: { uri_reference: uri } }
        end
      end
    end
  end

  class AnnotationPropertyID
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |_input|
        Yaparc::Apply.new(URIReference.new) do |uri|
          { annotation_property_id: uri }
        end
      end
    end
  end

  class OntologyPropertyID
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |_input|
        Yaparc::Apply.new(URIReference.new) do |uri|
          { ontology_property_id: { uri_reference: uri } }
        end
      end
    end
  end

  class ClassID
    include Yaparc::Parsable

    def initialize
      @parser = lambda do |_input|
        Yaparc::Apply.new(URIReference.new) do |uri|
          { class_id: uri }
        end
      end
    end
  end

  class IndividualID
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |_input|
        Yaparc::Apply.new(URIReference.new) do |uri|
          { individual_id: uri }
        end
      end
    end
  end

  class DatatypeID
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |_input|
        Yaparc::Apply.new(URIReference.new) do |uri|
          { datatype_id: { uri_reference: uri } }
        end
      end
    end
  end

  class DataLiteral
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |_input|
        Yaparc::Alt.new(TypedLiteral.new,
                        PlainLiteral.new)
      end
    end
  end

  class TypedLiteral
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |_input|
        Yaparc::Seq.new(LexicalForm.new,
                        Yaparc::Literal.new('^^'),
                        URIReference.new) do |lexical_form, _, uri|
          ["#{lexical_form}^^#{uri}"]
        end
      end
    end
  end

  class PlainLiteral
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |_input|
        Yaparc::Alt.new(Yaparc::Seq.new(LexicalForm.new,
                                        Yaparc::Literal.new('@'),
                                        LanguageTag.new) do |lexical_form, _, language_tag|
                          [lexical_form + '@' + language_tag]
                        end,
                        LexicalForm.new)
      end
    end
  end

  class LexicalForm
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |_input|
        Yaparc::Apply.new(Yaparc::Regex.new(/"[^"]*"/)) do |lexical_form|
          lexical_form
        end
      end
    end
  end

  class LanguageTag
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |_input|
        Yaparc::Regex.new(/[a-zA-Z-]+/)
      end
    end
  end

  class URIReference
    include Yaparc::Parsable

    def initialize
      @parser = lambda do |input|
        keyword_parsers = OWLParser::KEYWORDS.map { |keyword| Yaparc::Literal.new(keyword) }
        case result = Yaparc::Alt.new(*keyword_parsers).parse(input)
        when Yaparc::OK
          return Yaparc::FailParser.new
        end

        parser = Yaparc::Tokenize.new(
          Yaparc::Regex.new(%r{\A(([^:/?# ]+):)?(//([^/?#() ]*))?([^?#() ]*)(\?([^# ]*))?(#(.*))?}), prefix: Yaparc::Space.new, postfix: Yaparc::Space.new
        )
        case result = parser.parse(input)
        when Yaparc::OK
          if result.value.empty?
            Yaparc::FailParser.new
          else
            Yaparc::OK.new(value: { uri_reference: result.value }, input: result.input)
          end
        else
          result
        end
      end
    end
  end
end
