=begin
ontology ::= 'Ontology(' [ ontologyID ] { directive } ')'
directive ::= 'Annotation(' ontologyPropertyID ontologyID ')'
	 | 'Annotation(' annotationPropertyID URIreference ')'
         | 'Annotation(' annotationPropertyID dataLiteral ')'
         | 'Annotation(' annotationPropertyID individual ')'
         | axiom
         | fact
datatypeID ::= URIreference
classID ::= URIreference
individualID ::= URIreference
ontologyID ::= URIreference
datavaluedPropertyID ::= URIreference
individualvaluedPropertyID ::= URIreference
annotationPropertyID ::= URIreference
ontologyPropertyID ::= URIreference

fact ::= individual 
axiom ::= 'Class(' classID  ['Deprecated'] modality { annotation } { description } ')'
        | 'EnumeratedClass(' classID ['Deprecated'] { annotation } { individualID } ')'
        | 'DisjointClasses(' description description { description } ')'
        | 'EquivalentClasses(' description { description } ')'
        | 'SubClassOf(' description description ')'
        | 'Datatype(' datatypeID ['Deprecated']  { annotation } )'
        | 'DatatypeProperty(' datavaluedPropertyID ['Deprecated'] { annotation } { 'super(' datavaluedPropertyID ')'} ['Functional'] { 'domain(' description ')' } { 'range(' dataRange ')' } ')'
        | 'ObjectProperty(' individualvaluedPropertyID ['Deprecated'] { annotation } { 'super(' individualvaluedPropertyID ')' } [ 'inverseOf(' individualvaluedPropertyID ')' ] [ 'Symmetric' ] [ 'Functional' | 'InverseFunctional' | 'Functional' 'InverseFunctional' | 'Transitive' ] { 'domain(' description ')' } { 'range(' description ')' } ')'
        | 'AnnotationProperty(' annotationPropertyID { annotation } ')'
        | 'OntologyProperty(' ontologyPropertyID { annotation } ')'
        | 'EquivalentProperties(' datavaluedPropertyID datavaluedPropertyID  { datavaluedPropertyID } ')'
        | 'SubPropertyOf(' datavaluedPropertyID  datavaluedPropertyID ')'
        | 'EquivalentProperties(' individualvaluedPropertyID individualvaluedPropertyID { individualvaluedPropertyID } ')'
        | 'SubPropertyOf(' individualvaluedPropertyID  individualvaluedPropertyID ')'

individual ::= 'Individual(' [ individualID ] { annotation } { 'type(' type ')' } { value } ')'
value ::= 'value(' individualvaluedPropertyID individualID ')'
        | 'value(' individualvaluedPropertyID  individual ')'
        | 'value(' datavaluedPropertyID  dataLiteral ')'
annotation ::= 'annotation(' annotationPropertyID URIreference ')'
            | 'annotation(' annotationPropertyID dataLiteral ')'
            | 'annotation(' annotationPropertyID individual ')'

type ::= description



description ::= classID
            | restriction
            | 'unionOf(' { description } ')'
            | 'intersectionOf(' { description } ')'
            | 'complementOf(' description ')'
            | 'oneOf(' { individualID } ')'

restriction ::= 'restriction(' datavaluedPropertyID dataRestrictionComponent { dataRestrictionComponent } ')'
            | 'restriction(' individualvaluedPropertyID individualRestrictionComponent { individualRestrictionComponent } ')'

individualRestrictionComponent ::= 'allValuesFrom(' description ')'
            | 'someValuesFrom(' description ')'
            | 'value(' individualID ')'
            | cardinality 
modality ::= 'complete' | 'partial'

dataRestrictionComponent ::= 'allValuesFrom(' dataRange ')'
            | 'someValuesFrom(' dataRange ')'
            | 'value(' dataLiteral ')'
            | cardinality

cardinality ::= 'minCardinality(' non-negative-integer ')'
            | 'maxCardinality(' non-negative-integer ')'
            | 'cardinality(' non-negative-integer ')'
dataRange ::= datatypeID
            | 'rdfs:Literal'
            | 'oneOf(' { dataLiteral } ')'


# http://www.w3.org/TR/rdf-concepts/#dfn-plain-literal
dataLiteral ::= typedLiteral | plainLiteral
typedLiteral ::= lexicalForm^^URIreference
plainLiteral ::= lexicalForm | lexicalForm@languageTag
lexicalForm ::= /"[^"]*"/ # as in RDF, a unicode string in normal form C
languageTag ::= /[a-z-]+/ # as in RDF, an XML language tag
=end

module OWLParser
  KEYWORDS = %w{Ontology( Class( EnumeratedClass( DisjointClasses( EquivalentClasses( SubClassOf( Datatype( DatatypeProperty( ObjectProperty( AnnotationProperty( OntologyProperty( EquivalentProperties( SubPropertyOf( EquivalentProperties( type( Annotation( Individual( value( unionOf( intersectionOf( complementOf( oneOf( restriction( allValuesFrom( someValuesFrom( (minCardinality( maxCardinality( cardinality( rdfs:Literal}

  # ontology ::= 'Ontology(' [ ontologyID ] { directive } ')'
  class Ontology
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        Yaparc::Seq.new(Yaparc::Literal.new('Ontology('),
                        Yaparc::ZeroOne.new(OntologyID.new,{}),
                        Yaparc::Many.new(Directive.new,{}),
                        Yaparc::Literal.new(')')) do |_,ontologyID, directive,_|
          {:ontologyID => ontologyID, :directive => directive}
        end
      end
    end
  end 
  
  # directive ::= 'Annotation(' ontologyPropertyID ontologyID ')'
  # 	         | 'Annotation(' annotationPropertyID URIreference ')'
  #              | 'Annotation(' annotationPropertyID dataLiteral ')'
  #              | 'Annotation(' annotationPropertyID individual ')'
  #              | axiom
  #              | fact
  class Directive
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        Yaparc::Alt.new(Yaparc::Seq.new(Yaparc::Literal.new('Annotation('),
                                        OntologyPropertyID.new,
                                        OntologyID.new,
                                        Yaparc::Literal.new(')')) do |_,ontology_property_id,ontology_id,_|
                          {:ontology_property_id => ontology_property_id, :ontology_id => ontology_id }
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

  # axiom ::= 'Class(' classID  ['Deprecated'] modality { annotation } { description } ')'
  #         | 'EnumeratedClass(' classID ['Deprecated'] { annotation } { individualID } ')'
  #         | 'DisjointClasses(' description description { description } ')'
  #         | 'EquivalentClasses(' description { description } ')'
  #         | 'SubClassOf(' description description ')'
  #         | 'Datatype(' datatypeID ['Deprecated']  { annotation } )'
  #         | 'DatatypeProperty(' datavaluedPropertyID ['Deprecated'] { annotation } { 'super(' datavaluedPropertyID ')'} ['Functional'] { 'domain(' description ')' } { 'range(' dataRange ')' } ')'
  #         | 'ObjectProperty(' individualvaluedPropertyID ['Deprecated'] { annotation } { 'super(' individualvaluedPropertyID ')' } [ 'inverseOf(' individualvaluedPropertyID ')' ] [ 'Symmetric' ] [ 'Functional' | 'InverseFunctional' | 'Functional' 'InverseFunctional' | 'Transitive' ] { 'domain(' description ')' } { 'range(' description ')' } ')'
  #         | 'AnnotationProperty(' annotationPropertyID { annotation } ')'
  #         | 'OntologyProperty(' ontologyPropertyID { annotation } ')'
  #         | 'EquivalentProperties(' datavaluedPropertyID datavaluedPropertyID  { datavaluedPropertyID } ')'
  #         | 'SubPropertyOf(' datavaluedPropertyID  datavaluedPropertyID ')'
  #         | 'EquivalentProperties(' individualvaluedPropertyID individualvaluedPropertyID { individualvaluedPropertyID } ')'
  #         | 'SubPropertyOf(' individualvaluedPropertyID  individualvaluedPropertyID ')'
  
  class Axiom
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        Yaparc::Alt.new(#'Class(' classID  ['Deprecated'] modality { annotation } { description } ')'
                        Yaparc::Seq.new(Yaparc::Literal.new('Class('),
                                        ClassID.new,
                                        Yaparc::ZeroOne.new(Yaparc::Literal.new('Deprecated'),{}), 
                                        Modality.new,
                                        Yaparc::Many.new(Annotation.new,{}),
                                        Yaparc::Many.new(Description.new,{}),
                                        Yaparc::Literal.new(')')) do |_,class_id, deprecated, modality, annotations, descriptions,_|
                          {:class => {:class_id => class_id, :deprecated => deprecated, :modality => modality, :annotations => annotations, :descriptions => descriptions }}
                        end,
                        #'EnumeratedClass(' classID ['Deprecated'] { annotation } { individualID } ')'
                        Yaparc::Seq.new(Yaparc::Literal.new('EnumeratedClass('),
                                        ClassID.new,
                                        Yaparc::ZeroOne.new(Yaparc::Literal.new('Deprecated'),{}),
                                        Yaparc::Many.new(Annotation.new,{}),
                                        Yaparc::Many.new(IndividualID.new,{}),
                                        Yaparc::Literal.new(')')) do |_,class_id, deprecated, annotations, individual_ids,_|
                          {:enumerated_class => {:class_id => class_id, :deprecated => deprecated, :annotations => annotations, :individual_ids => individual_ids }}
                        end,
                        #'DisjointClasses(' description description { description } ')'
                        Yaparc::Seq.new(Yaparc::Literal.new('DisjointClasses('),
                                        Description.new,
                                        Yaparc::ManyOne.new(Description.new,{}),
                                        Yaparc::Literal.new(')')) do |_,description,descriptions,_|
                          {:disjoint_classes => description.merge(descriptions)}
                        end,
                        #'EquivalentClasses(' description { description } ')'
                        Yaparc::Seq.new(Yaparc::Literal.new('EquivalentClasses('),
                                        Yaparc::ManyOne.new(Description.new,{ }),
                                        Yaparc::Literal.new(')')) do |_,descriptions,_|
                          {:equivalent_classes => descriptions}
                        end,
                        #'SubClassOf(' description description ')'
                        Yaparc::Seq.new(Yaparc::Literal.new('SubClassOf('),
                                        Description.new,
                                        Description.new,
                                        Yaparc::Literal.new(')')) do |_,description1,description2,_|
                          {:sub_class_of => description1.merge(description2)}
                        end,
                        #'Datatype(' datatypeID ['Deprecated']  { annotation } )'
                        Yaparc::Seq.new(Yaparc::Literal.new('Datatype('),
                                        DatatypeID.new, 
                                        Yaparc::ZeroOne.new(Yaparc::Literal.new('Deprecated'),{}), 
                                        Yaparc::Many.new(Annotation.new,{ }),
                                        Yaparc::Literal.new(')')) do |_,datatype_id,_,annotations,_|
                          {:datatype => {:datatype_id => datatype_id,:annotations=> annotations }}
                        end,
                        #'DatatypeProperty(' datavaluedPropertyID ['Deprecated'] { annotation } { 'super(' datavaluedPropertyID ')'} ['Functional'] { 'domain(' description ')' } { 'range(' dataRange ')' } ')'
                        Yaparc::Seq.new(Yaparc::Literal.new('DatatypeProperty('),
                                        DatavaluedPropertyID.new,
                                        Yaparc::ZeroOne.new(Yaparc::Literal.new('Deprecated'),{}),
                                        Yaparc::Many.new(Annotation.new,{ }),
                                        Yaparc::Many.new(
                                                         Yaparc::Seq.new(Yaparc::Literal.new('super('),
                                                                         DatavaluedPropertyID.new,
                                                                         Yaparc::Literal.new(')')),{}),
                                        Yaparc::ZeroOne.new(Yaparc::Literal.new('Functional'),{}),
                                        Yaparc::Many.new(
                                                         Yaparc::Seq.new(Yaparc::Literal.new('domain('),
                                                                         Description.new,
                                                                         Yaparc::Literal.new(')')),{}),
                                        Yaparc::Many.new(
                                                         Yaparc::Seq.new(Yaparc::Literal.new('range('),
                                                                         DataRange.new,
                                                                         Yaparc::Literal.new(')')),{}),
                                        Yaparc::Literal.new(')')) do |_, datavalued_property_id, _, annotation, super_tag, functional, domain, range,_|
                          {:datatype_property_id => {:annotation => annotation, :super_tag => super_tag, :functional =>  functional, :domain => domain, :range => range}}
                        end,
                        #'ObjectProperty(' individualvaluedPropertyID ['Deprecated'] { annotation } { 'super(' individualvaluedPropertyID ')' } [ 'inverseOf(' individualvaluedPropertyID ')' ] [ 'Symmetric' ] [ 'Functional' | 'InverseFunctional' | 'Functional' 'InverseFunctional' | 'Transitive' ] { 'domain(' description ')' } { 'range(' description ')' } ')'
                        Yaparc::Seq.new(Yaparc::Literal.new('ObjectProperty('),
                                        IndividualvaluedPropertyID.new, 
                                        Yaparc::ZeroOne.new(Yaparc::Literal.new('Deprecated'),{}), 
                                        Yaparc::Many.new(Annotation.new,{}),
                                        Yaparc::Many.new(
                                                         Yaparc::Seq.new(Yaparc::Literal.new('super('),
                                                                         IndividualvaluedPropertyID.new,
                                                                         Yaparc::Literal.new(')')),{}),
                                        Yaparc::Many.new(
                                                         Yaparc::Seq.new(Yaparc::Literal.new('inverseOf('),
                                                                         IndividualvaluedPropertyID.new,
                                                                         Yaparc::Literal.new(')')),{}),
                                        Yaparc::ZeroOne.new(Yaparc::Literal.new('Symmetric'),{}),
                                        Yaparc::Alt.new(
                                                        Yaparc::Literal.new('Functional'),
                                                        Yaparc::Literal.new('InverseFunctional'),
                                                        Yaparc::Seq.new(Yaparc::Literal.new('Functional'), Yaparc::Literal.new('InverseFunctional')),
                                                        Yaparc::Literal.new('Transitive')),
                                        Yaparc::Many.new(
                                                         Yaparc::Seq.new(Yaparc::Literal.new('domain('),
                                                                         Description.new,
                                                                         Yaparc::Literal.new(')')),{}),
                                        Yaparc::Many.new(
                                                         Yaparc::Seq.new(Yaparc::Literal.new('range('),
                                                                         Description.new,
                                                                         Yaparc::Literal.new(')')),{}),
                                        
                                        Yaparc::Literal.new(')')) do |_,individualvaluedPropertyID1, deprecated, annotation, super_tag,inverseOf,symmetric, functional, domain, range, _|
                          {:object_property => {}}
                        end,
                        #'AnnotationProperty(' annotationPropertyID { annotation } ')'
                        Yaparc::Seq.new(Yaparc::Literal.new('AnnotationPropertyID('),
                                        AnnotationPropertyID.new,
                                        Yaparc::ManyOne.new(Annotation.new,{}),
                                        Yaparc::Literal.new(')')) do |_, annotationPropertyID, annotation,_|
                          {:annotationProperty => {:annotationPropertyID => annotationPropertyID, :annotation => annotation }}
                        end,
                        #'OntologyProperty(' ontologyPropertyID { annotation } ')'
                        Yaparc::Seq.new(Yaparc::Literal.new('OntologyProperty('),
                                        OntologyPropertyID.new,
                                        Yaparc::ManyOne.new(Annotation.new,{}),
                                        Yaparc::Literal.new(')')) do |_, ontologyPropertyID, annotation,_|
                          {:OntologyProperty => {:ontologyPropertyID => ontologyPropertyID, :annotation => annotation }}
                        end,
                        #'EquivalentProperties(' datavaluedPropertyID datavaluedPropertyID  { datavaluedPropertyID } ')'
                        Yaparc::Seq.new(Yaparc::Literal.new('EquivalentProperties('),
                                        DatavaluedPropertyID.new,
                                        Yaparc::ManyOne.new(DatavaluedPropertyID.new,{}),
                                        Yaparc::Literal.new(')')) do |_,datavaluedPropertyID, datavaluedPropertyIDs,_|
                          {:equivalentProperties => {}}
                        end,
                        #'SubPropertyOf(' datavaluedPropertyID  datavaluedPropertyID ')'
                        Yaparc::Seq.new(Yaparc::Literal.new('SubPropertyOf('),
                                        DatavaluedPropertyID.new,
                                        DatavaluedPropertyID.new,
                                        Yaparc::Literal.new(')')) do |_,datavaluedPropertyID1, datavaluedPropertyID2,_|
                          {:subPropertyOf => {}}
                        end,
                        #'EquivalentProperties(' individualvaluedPropertyID individualvaluedPropertyID { individualvaluedPropertyID } ')'
                        Yaparc::Seq.new(Yaparc::Literal.new('EquivalentProperties('),
                                        IndividualvaluedPropertyID.new,
                                        Yaparc::ManyOne.new(IndividualvaluedPropertyID.new,{}),
                                        Yaparc::Literal.new(')')) do |_,individualvaluedPropertyID,individualvaluedPropertyIDs,_|
                          {:equivalentProperties => {}}
                        end,
                        #'SubPropertyOf(' individualvaluedPropertyID  individualvaluedPropertyID ')'
                        Yaparc::Seq.new(Yaparc::Literal.new('SubPropertyOf('),
                                        IndividualvaluedPropertyID.new,
                                        IndividualvaluedPropertyID.new,
                                        Yaparc::Literal.new(')')) do |_,individualvaluedPropertyID1, individualvaluedPropertyID2,_|
                          {:subPropertyOf => { }}
                        end)
      end
    end
  end

  # fact ::= individual 
  class Fact
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        Individual.new
      end
    end
  end

  # individual ::= 'Individual(' [ individualID ] { annotation } { 'type(' type ')' } { value } ')'
  class Individual
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        Yaparc::Seq.new(Yaparc::Literal.new('Individual('),
                        Yaparc::ZeroOne.new(IndividualID.new,{}),
                        Yaparc::Many.new(Annotation.new,{ }),
                        Yaparc::Many.new(
                                         Yaparc::Seq.new(Yaparc::Literal.new('type('), 
                                                         Type.new,
                                                         Yaparc::Literal.new(')')) do |_, type, _| 
                                           {:type => type}
                                         end,{}),
#                         Yaparc::Apply.new(Yaparc::Many.new(Value.new,{ })) do |value|
#                           {:value => value}
#                         end,
                        Yaparc::Many.new(Value.new,{ }),
                        Yaparc::Literal.new(')')) do |_,individual_id, annotations, types, values,_|
          individual_id.merge(annotations).merge(types).merge(values)
#          {:individual_id => individual_id, :annotations => annotations, :types => types, :values => values}
        end
      end
    end
  end
  
  # annotation ::= 'annotation(' annotationPropertyID URIreference ')'
  #              | 'annotation(' annotationPropertyID dataLiteral ')'
  #              | 'annotation(' annotationPropertyID individual ')'
  class Annotation
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        Yaparc::Alt.new(Yaparc::Seq.new(Yaparc::Literal.new('annotation('),
                                        AnnotationPropertyID.new,
                                        URIReference.new,
                                        Yaparc::Literal.new(')')) do |_,annotation_property_id, uri_reference, _|
                          {:annotation_property_id => annotation_property_id, :uri_reference => uri_reference }
                        end,
                        Yaparc::Seq.new(Yaparc::Literal.new('annotation('),
                                        AnnotationPropertyID.new,
                                        DataLiteral.new,
                                        Yaparc::Literal.new(')')) do |_,annotation_property_id, data_literal, _|
                          {:annotation_property_id => annotation_property_id, :data_literal => data_literal}
                        end,
                        Yaparc::Seq.new(Yaparc::Literal.new('annotation('),
                                        AnnotationPropertyID.new,
                                        Individual.new,
                                        Yaparc::Literal.new(')')) do |_,annotation_property_id, individual, _|
                          {:annotation_property_id => annotation_property_id, :individual => individual }
                        end)
      end
    end
  end


  # value ::= 'value(' individualvaluedPropertyID individualID ')'
  #         | 'value(' individualvaluedPropertyID  individual ')'
  #         | 'value(' datavaluedPropertyID  dataLiteral ')'
  class Value
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        Yaparc::Alt.new(Yaparc::Seq.new(Yaparc::Literal.new('value('),
                                        IndividualvaluedPropertyID.new,
                                        IndividualID.new,
                                        Yaparc::Literal.new(')')) do |_,individualvalued_property_id, individual_id,_|
                          {:individualvalued_property_id => individualvalued_property_id, :individual_id => individual_id }
                        end,
                        Yaparc::Seq.new(Yaparc::Literal.new('value('),
                                        IndividualvaluedPropertyID.new,
                                        Individual.new,
                                        Yaparc::Literal.new(')')) do |_,individualvalued_property_id, individual,_|
                          {:individualvalued_property_id => individualvalued_property_id, :individual => individual}
                        end,
                        Yaparc::Seq.new(Yaparc::Literal.new('value('),
                                        IndividualvaluedPropertyID.new,
                                        DataLiteral.new,
                                        Yaparc::Literal.new(')')) do |_,individualvalued_property_id, data_literal,_|
                          {:individualvalued_property_id => individualvalued_property_id, :data_literal => data_literal}
                          
                        end)
      end
    end
  end

  # type ::= description
  class Type
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        Description.new
      end
    end
  end

  # description ::= classID
  #             | restriction
  #             | 'unionOf(' { description } ')'
  #             | 'intersectionOf(' { description } ')'
  #             | 'complementOf(' description ')'
  #             | 'oneOf(' { individualID } ')'
  class Description
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        Yaparc::Alt.new(Restriction.new,
                        Yaparc::Seq.new(Yaparc::Literal.new('unionOf('),
                                        Yaparc::Many.new(Description.new,{ }),
                                        Yaparc::Literal.new(')')) do |_,description,_|
                          {:unionOf => description}
                        end,
                        Yaparc::Seq.new(Yaparc::Literal.new('intersectionOf('),
                                        Yaparc::Many.new(Description.new,{ }),
                                        Yaparc::Literal.new(')')) do |_,description,_|
                          {:intersectionOf => description}
                        end,
                        Yaparc::Seq.new(Yaparc::Literal.new('complementOf('),
                                        Description.new,
                                        Yaparc::Literal.new(')')) do |_,description,_|
                          {:complementOf => description}
                        end,
                        Yaparc::Seq.new(Yaparc::Literal.new('oneOf('),
                                        Yaparc::Many.new(IndividualID.new,{}),
                                        Yaparc::Literal.new(')')) do |_,description,_|
                          {:oneOf => {:individual_id => description}}
                        end,
                        ClassID.new)
      end
    end
  end

  # restriction ::= 'restriction(' datavaluedPropertyID dataRestrictionComponent { dataRestrictionComponent } ')'
  #               | 'restriction(' individualvaluedPropertyID individualRestrictionComponent { individualRestrictionComponent } ')'
  class Restriction
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        Yaparc::Alt.new(Yaparc::Seq.new(Yaparc::Literal.new('restriction('), 
                                        DatavaluedPropertyID.new, 
                                        Yaparc::ManyOne.new(DataRestrictionComponent.new,{ }),
                                        Yaparc::Literal.new(')')) do |_,datavalued_property_id, data_restriction_components,_|
                          {:datavalued_property_id => datavalued_property_id, :data_restriction_components => data_restriction_components}
                        end,
                        Yaparc::Seq.new(Yaparc::Literal.new('restriction('), 
                                        IndividualvaluedPropertyID.new, 
                                        Yaparc::ManyOne.new(IndividualRestrictionComponent.new,{ }),
                                        Yaparc::Literal.new(')')) do |_,individualvalued_property_id, individual_restriction_components,_|
                          {:individualvalued_property_id => individualvalued_property_id, :individual_restriction_components => individual_restriction_components}
                        end)
      end
    end
  end
  
  # individualRestrictionComponent ::= 'allValuesFrom(' description ')'
  #             | 'someValuesFrom(' description ')'
  #             | 'value(' individualID ')'
  #             | cardinality 
  class IndividualRestrictionComponent
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        Yaparc::Alt.new(Yaparc::Seq.new(Yaparc::Literal.new('allValuesFrom('), 
                                        Description.new,
                                        Yaparc::Literal.new(')')) do |_,description,_|
                          {:allValuesFrom => description}
                        end,
                        Yaparc::Seq.new(Yaparc::Literal.new('someValuesFrom('), 
                                        Description.new,
                                        Yaparc::Literal.new(')')) do |_,description,_|
                          {:someValuesFrom => description}
                        end,
                        Yaparc::Seq.new(Yaparc::Literal.new('value('), 
                                        IndividualID.new, 
                                        Yaparc::Literal.new(')')) do |_,individual_id,_|
                          {:value => individual_id}
                        end,
                        Cardinality.new)
      end
    end
  end

  # modality ::= 'complete' | 'partial'
  class Modality
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        Yaparc::Alt.new(Yaparc::Literal.new('complete'),Yaparc::Literal.new('partial'))
      end
    end
  end

  # dataRestrictionComponent ::= 'allValuesFrom(' dataRange ')'
  #                            | 'someValuesFrom(' dataRange ')'
  #                            | 'value(' dataLiteral ')'
  #                            | cardinality
  class DataRestrictionComponent
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        Yaparc::Alt.new(Yaparc::Seq.new(Yaparc::Literal.new('allValuesFrom('),
                                        DataRange.new,
                                        Yaparc::Literal.new(')')) do |_,data_range,_|
                          {:allValuesFrom => data_range }
                        end,
                        Yaparc::Seq.new(Yaparc::Literal.new('someValuesFrom('), 
                                        DataRange.new, 
                                        Yaparc::Literal.new(')')) do |_,data_range,_|
                          {:someValuesFrom => data_range }
                        end,
                        Yaparc::Seq.new(Yaparc::Literal.new('value('),
                                        DataLiteral.new,
                                        Yaparc::Literal.new(')')) do |_,data_literal,_|
                          {:value => data_literal }
                        end,
                        Cardinality.new)
      end
    end
  end

  # cardinality ::= 'minCardinality(' non-negative-integer ')'
  #             | 'maxCardinality(' non-negative-integer ')'
  #             | 'cardinality(' non-negative-integer ')'

  class Cardinality
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        Yaparc::Alt.new(Yaparc::Seq.new(Yaparc::Literal.new('minCardinality('),
                                        Yaparc::Many.new(NonNegativeInteger.new,0),
                                        Yaparc::Literal.new(')')) do |_,integer,_|
                          {:minCardinality => integer}
                        end,
                        Yaparc::Seq.new(Yaparc::Literal.new('maxCardinality('),
                                        Yaparc::Many.new(NonNegativeInteger.new,0),
                                                    Yaparc::Literal.new(')')) do |_,integer,_|
                                {:maxCardinality => integer}
                              end,
                              Yaparc::Seq.new(Yaparc::Literal.new('cardinality('),
                                                    Yaparc::Many.new(NonNegativeInteger.new,0),
                                                    Yaparc::Literal.new(')')) do |_,integer,_|
                                {:cardinality => integer}
                              end)
      end
    end
  end

  class NonNegativeInteger
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        Yaparc::Apply.new(Yaparc::Regex.new(/\A[0-9]+/)) do |number|
          Integer(number)
        end
      end
    end
  end


  # dataRange ::= datatypeID
  #            | 'rdfs:Literal'
  #            | 'oneOf(' { dataLiteral } ')'
  class DataRange
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        Yaparc::Alt.new(Yaparc::Literal.new('rdfs:Literal'),
                        Yaparc::Seq.new(Yaparc::Literal.new('oneOf('),
                                        Yaparc::Many.new(DataLiteral.new,[]),
                                        Yaparc::Literal.new(')')) do |_,data_literals,_|
                          {:oneOf => data_literals}
                        end,
                        DatatypeID.new)
      end
    end
  end

  # ontologyID ::= URIreference
  class OntologyID
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        Yaparc::Apply.new(URIReference.new) do |uri|
          {:ontology_id => uri}
        end
      end
    end
  end

  # datavaluedPropertyID ::= URIreference
  class DatavaluedPropertyID
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        Yaparc::Apply.new(URIReference.new) do |uri|
          {:datavalued_property_id => {:uri_reference => uri}}
        end
        #URIReference.new
        #URIParser::URIReference.new
      end
    end
  end


  # individualvaluedPropertyID ::= URIreference
  class IndividualvaluedPropertyID
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        Yaparc::Apply.new(URIReference.new) do |uri|
          {:individualvalued_property_id => {:uri_reference => uri}}
        end
      end
    end
  end

  # annotationPropertyID ::= URIreference
  class AnnotationPropertyID
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        Yaparc::Apply.new(URIReference.new) do |uri|
          {:annotation_property_id => uri}
        end
      end
    end
  end

  # ontologyPropertyID ::= URIreference
  class OntologyPropertyID
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        Yaparc::Apply.new(URIReference.new) do |uri|
          {:ontology_property_id => {:uri_reference => uri}}
        end
      end
    end
  end

  # classID ::= URIreference
  class ClassID
    include Yaparc::Parsable

    def initialize
      @parser = lambda do |input|
        Yaparc::Apply.new(URIReference.new) do |uri|
          {:class_id => uri}
        end
      end
    end
  end

  # individualID ::= URIreference
  class IndividualID
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        Yaparc::Apply.new(URIReference.new) do |uri|
          {:individual_id => uri}
        end
      end
    end
  end

  # datatypeID ::= URIreference
  class DatatypeID
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        Yaparc::Apply.new(URIReference.new) do |uri|
          {:datatype_id => {:uri_reference => uri}}
        end
      end
    end
  end

  # dataLiteral ::= typedLiteral | plainLiteral
  class DataLiteral
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        Yaparc::Alt.new(TypedLiteral.new,
                        PlainLiteral.new)
      end
    end
  end

  # typedLiteral ::= lexicalForm^^URIreference
  class TypedLiteral
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        Yaparc::Seq.new(LexicalForm.new,
                        Yaparc::Literal.new('^^'),
                        URIReference.new) do |lexical_form, _, uri|
          ["#{lexical_form}^^#{uri}"]
        end
      end
    end
  end

  # plainLiteral ::= lexicalForm | lexicalForm@languageTag
  class PlainLiteral
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        Yaparc::Alt.new(Yaparc::Seq.new(LexicalForm.new, 
                                        Yaparc::Literal.new('@'), 
                                        LanguageTag.new) do |lexical_form,_,language_tag|
                          [lexical_form + '@' + language_tag]
                        end,
                        LexicalForm.new)
      end
    end
  end

  #lexicalForm ::= as in RDF, a unicode string in normal form C
  class LexicalForm
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        Yaparc::Apply.new(Yaparc::Regex.new(/"[^"]*"/)) do |lexical_form|
          lexical_form
        end
      end
    end
  end

  #languageTag ::= as in RDF, an XML language tag
  class LanguageTag
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        Yaparc::Regex.new(/[a-zA-Z-]+/)
      end
    end
  end

  # ^(([^:/?#]+):)?(//([^/?#]*))?([^?#]*)(\?([^#]*))?(#(.*))?
  class URIReference
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        
        keyword_parsers = OWLParser::KEYWORDS.map {|keyword| Yaparc::Literal.new(keyword)}
        case result = Yaparc::Alt.new(*keyword_parsers).parse(input)
        when Yaparc::Result::OK
          return Yaparc::Fail.new
        end

        parser = Yaparc::Tokenize.new(Yaparc::Regex.new(/\A(([^:\/?# ]+):)?(\/\/([^\/?#() ]*))?([^?#() ]*)(\?([^# ]*))?(#(.*))?/), :prefix => Yaparc::Space.new, :postfix => Yaparc::Space.new)
        case result = parser.parse(input)
        when Yaparc::Result::OK
          unless result.value.empty?
            Yaparc::Result::OK.new(:value => {:uri_reference => result.value}, :input => result.input)
          else
            Yaparc::Fail.new
          end
        else
          result
        end
      end
    end
  end
end


class OwlTest < Test::Unit::TestCase
  include ::Yaparc

  def test_ontology
    ontology = OWLParser::Ontology.new
    result = ontology.parse("Ontology()")
    assert_instance_of Result::OK, result
    result = ontology.parse("Ontology(ex:ontology_id)")
    assert_instance_of Result::OK, result
    result = ontology.parse("Ontology(Class(ex:class complete annotation(ex:annotation http://localhost.localdomain )))")
    assert_instance_of Result::OK, result
    result = ontology.parse("Ontology(Class(ex:class Deprecated partial annotation(ex:annotation http://localhost.localdomain )))")
    assert_instance_of Result::OK, result

    ontology1 = <<-EOS
     Ontology(ontology1
       Class(Pc complete unionOf(Desktop Laptop))
       Individual(ibmR40 type(Laptop))
       Individual(compaqPresario200 type(Desktop))
       Class(PcOffice complete intersectionOf(Pc complementOf(Desktop))))
    EOS
    result = ontology.parse(ontology1)
    assert_instance_of Result::OK, result
  end

  def test_directive
    directive = OWLParser::Directive.new
    result = directive.parse("Class(ex:class complete )")
    assert_instance_of Result::OK, result
    result = directive.parse("Class(ex:class complete annotation(ex:annotation http://localhost.localdomain ))")
    assert_instance_of Result::OK, result
    result = directive.parse("Class(ex:class Deprecated partial annotation(ex:annotation http://localhost.localdomain ))")
    assert_instance_of Result::OK, result
  end

 def test_axiom
   axiom = OWLParser::Axiom.new
   result = axiom.parse("Class(Pc complete unionOf(Desktop Laptop))")
   assert_instance_of Result::OK, result
   result = axiom.parse("Class(ex:class_id complete )")
   assert_instance_of Result::OK, result
   result = axiom.parse("EnumeratedClass(ex:class_id Deprecated )")
   assert_instance_of Result::OK, result
   result = axiom.parse("Class(ex:class complete annotation(ex:annotation http://localhost.localdomain ))")
   assert_instance_of Result::OK, result
   result = axiom.parse("Class(ex:class Deprecated partial annotation(ex:annotation http://localhost.localdomain ))")
   result = axiom.parse("SubClassOf(ex:subclass ex:superclass)")
   assert_instance_of Result::OK, result
 end

  def test_annotation
    annotation = OWLParser::Annotation.new
    result = annotation.parse("annotation(ex:annotation http://localhost.localdomain)")
    assert_instance_of Result::OK, result
    result = annotation.parse("annotation(ex:annotation type(ex:human))")
    assert_instance_of Result::Fail, result
    result = annotation.parse('annotation(ex:annotation "akimichi"^^http://www.w3.org/2001/XMLSchema@integer)')
    assert_instance_of Result::OK, result
    assert_instance_of Result::Fail, annotation.parse("annotation(ex:annotation value(ex:human))")
    assert_instance_of Result::Fail, annotation.parse("annotation(ex:annotation type(ex:human) value(ex:human))")
  end

  def test_value
    value = OWLParser::Value.new
    result = value.parse("value(ex:value http://localhost.localdomain)")
    assert_instance_of Result::OK, result
  end

  def test_individual
    individual = OWLParser::Individual.new
    result = individual.parse("Individual(ex:individual)")
    assert_instance_of Result::OK, result
    assert_equal Hash[:individual_id=>{:uri_reference=>"ex:individual"}], result.value
    result = individual.parse("Individual(ex:individual type(ex:human))")
    assert_instance_of Result::OK, result
    assert_instance_of Result::OK, individual.parse("Individual(ex:individual type(ex:human))")
    assert_instance_of Result::OK, individual.parse("Individual(ex:individual value(ex:human http://localhost.localdomain))")
    assert_instance_of Result::OK, individual.parse("Individual(ex:individual type(ex:human) value(ex:human http://localhost.localdomain))")
  end

  def test_type
    type = OWLParser::Type.new
    assert_instance_of Result::OK, type.parse("http://localhost.localdomain")
    assert_instance_of Result::OK, type.parse("unionOf(  )")
    assert_instance_of Result::OK, type.parse("unionOf(Desktop Laptop)")
    assert_instance_of Result::OK, type.parse("unionOf(http://localhost.localdomain)")
    assert_instance_of Result::OK, type.parse("ex:hasMember")
    assert_instance_of Result::OK, type.parse("unionOf(ex:hasMember)")
    assert_instance_of Result::OK, type.parse("intersectionOf(ex:hasMember)")
    assert_instance_of Result::OK, type.parse("complementOf(intersectionOf(ex:hasMember))")
    assert_instance_of Result::OK, type.parse("oneOf(ex:hasMember)")
  end

  def test_description
    description = OWLParser::Description.new
    assert_instance_of Result::OK, description.parse("http://localhost.localdomain")
    assert_instance_of Result::OK, description.parse("unionOf(  )")
    assert_instance_of Result::OK, description.parse("unionOf(http://localhost.localdomain)")
    assert_instance_of Result::OK, description.parse("unionOf(Desktop Laptop)")
    assert_instance_of Result::OK, description.parse("ex:hasMember")
    assert_instance_of Result::OK, description.parse("unionOf(ex:hasMember)")
    assert_instance_of Result::OK, description.parse("intersectionOf(ex:hasMember)")
    assert_instance_of Result::OK, description.parse("complementOf(intersectionOf(ex:hasMember))")
    assert_instance_of Result::OK, description.parse("oneOf(ex:hasMember)")
    assert_instance_of Result::OK, description.parse("restriction(ex:hasMember allValuesFrom(ex:StringPlayer))")
  end

  def test_individual_restriction_component
    individual_restriction_component = OWLParser::IndividualRestrictionComponent.new
    result = individual_restriction_component.parse("allValuesFrom(ex:StringPlayer)")
    assert_instance_of Result::OK, result
    assert_equal "", result.input
    result = individual_restriction_component.parse("someValuesFrom(ex:StringPlayer)")
    assert_instance_of Result::OK, result
    assert_equal "", result.input
    result = individual_restriction_component.parse("value(ex:StringPlayer)")
    assert_instance_of Result::OK, result
    assert_equal "", result.input
    result = individual_restriction_component.parse("minCardinality(1)")
    assert_instance_of Result::OK, result
    assert_equal "", result.input
  end

  def test_restriction
    restriction = OWLParser::Restriction.new
    assert_instance_of Result::OK, restriction.parse("restriction(ex:hasMember value(datatype))")
    assert_instance_of Result::OK, restriction.parse("restriction(ex:hasMember allValuesFrom(ex:StringPlayer))")
  end


  def test_data_restriction_component
    data_restriction_component = OWLParser::DataRestrictionComponent.new
    assert_instance_of Result::OK, data_restriction_component.parse('value("akimichi"@ja)')
    assert_instance_of Result::OK, data_restriction_component.parse("allValuesFrom( rdfs:Literal )")
    assert_instance_of Result::OK, data_restriction_component.parse("allValuesFrom(ex:StringPlayer)")
    assert_instance_of Result::OK, data_restriction_component.parse("allValuesFrom(http://localhost.localdomain)")
    assert_instance_of Result::OK, data_restriction_component.parse("allValuesFrom(oneOf())")
    assert_instance_of Result::OK, data_restriction_component.parse('allValuesFrom(oneOf("akimichi"@ja))')
    assert_instance_of Result::OK, data_restriction_component.parse("maxCardinality(10)")
    assert_instance_of Result::OK, data_restriction_component.parse("cardinality(398)")
    assert_instance_of Result::OK, data_restriction_component.parse("minCardinality(1)")
    assert_instance_of Result::OK, data_restriction_component.parse("maxCardinality(10)")
    assert_instance_of Result::OK, data_restriction_component.parse("cardinality(398)")

  end

  def test_cardinality
    cardinality = OWLParser::Cardinality.new
    assert_instance_of Result::OK, cardinality.parse("minCardinality(1)")
    assert_instance_of Result::OK, cardinality.parse("maxCardinality(10)")
    assert_instance_of Result::OK, cardinality.parse("cardinality(398)")

  end

  def test_data_range
    data_range = OWLParser::DataRange.new
    assert_instance_of Result::OK, data_range.parse("datatype@localhost.localdomain")
    assert_instance_of Result::OK, data_range.parse("http://datatype@localhost.localdomain")
    assert_instance_of Result::OK, data_range.parse("http://localhost.localdomain")
    assert_instance_of Result::OK, data_range.parse("datatype@localhost.localdomain)")
    assert_instance_of Result::OK, data_range.parse("rdfs:Literal")
    assert_instance_of Result::OK, data_range.parse("oneOf()")
    assert_instance_of Result::OK, data_range.parse('oneOf("akimichi"@ja)')
#    assert_instance_of Result::OK, data_range.parse("oneOf( emile@datarange.localdomain )")
  end

  def test_data_literal
    data_literal = OWLParser::DataLiteral.new
    assert_instance_of Result::OK, data_literal.parse('"akimichi"@ja')
    assert_instance_of Result::OK, data_literal.parse('"akimichi"^^http://www.w3.org/2001/XMLSchema@integer')
    assert_instance_of Result::Fail, data_literal.parse("ex:hasMember")
    assert_instance_of Result::Fail, data_literal.parse("datatype")
    assert_instance_of Result::Fail, data_literal.parse("emile@localhost.localdomain")
  end

  def test_plain_literal
    plain_literal = OWLParser::PlainLiteral.new
    assert_instance_of Result::OK, plain_literal.parse('"akimichi"@ja')
    result = plain_literal.parse('"nick"@en-US')
    assert_instance_of Result::OK, result
    assert_equal ["\"nick\"@en-US"], result.value
    assert_instance_of Result::OK, plain_literal.parse('"akimichi"')
  end

  def test_typed_literal
    typed_literal = OWLParser::TypedLiteral.new
    assert_instance_of Result::OK, typed_literal.parse('"akimichi"^^http://www.w3.org/2001/XMLSchema@integer')
  end

  def test_lexical_form
    lexical_form = OWLParser::LexicalForm.new
    assert_instance_of Result::OK, lexical_form.parse('"ex:hasMember"')
    assert_instance_of Result::OK, lexical_form.parse('"datatype"')
    assert_instance_of Result::OK, lexical_form.parse('"emile@localhost.localdomain"')
  end

  def test_language_tag
    language_tag = OWLParser::LanguageTag.new
    assert_instance_of Result::OK, language_tag.parse("ja")
    result = language_tag.parse("en-US")
    assert_instance_of Result::OK, result
    assert_equal "en-US", result.value
  end

  def test_annotation_property_id
    annotation_property_id = OWLParser::AnnotationPropertyID.new
    result = annotation_property_id.parse("ex:annotation")
    assert_instance_of Result::OK, result
    assert_equal Hash[:annotation_property_id => {:uri_reference=>"ex:annotation"}], result.value
  end

  def test_individual_id
    individual_id = OWLParser::IndividualID.new
    assert_instance_of Result::Fail, individual_id.parse("type(")
    result = individual_id.parse("ex:individual")
    assert_instance_of Result::OK, result
    assert_equal "", result.input
    result = individual_id.parse("ex:individual type")
    assert_instance_of Result::OK, result
    assert_equal Hash[:individual_id => {:uri_reference=>"ex:individual"}], result.value
    assert_equal "type", result.input
    assert_instance_of Result::OK, individual_id.parse("http://localhost.localdomain:3000/pchar;param?query")
    assert_instance_of Result::OK, individual_id.parse("http://localhost.localdomain")
  end

  def test_ontology_id
    ontology_id = OWLParser::OntologyID.new
    assert_instance_of Result::OK, ontology_id.parse("http://localhost.localdomain:3000")
    result = ontology_id.parse("ex:individual type")
  end

  def test_class_id
    class_id = OWLParser::ClassID.new
    result = class_id.parse("ex:class_id")
    assert_instance_of Result::OK, result
    assert_equal Hash[:class_id=>{:uri_reference=>"ex:class_id"}], result.value
    result = class_id.parse("ex:individual")
    assert_instance_of Result::OK, class_id.parse("http://localhost.localdomain:3000")
    result = class_id.parse("ex:individual type")
    assert_instance_of Result::OK, result
    assert_equal Hash[:class_id=> {:uri_reference=>"ex:individual"}], result.value
    assert_equal "type", result.input
    assert_instance_of Result::OK, class_id.parse("http://localhost.localdomain:3000/pchar;param?query")
    assert_instance_of Result::OK, class_id.parse("http://localhost.localdomain")
  end

  def test_uri_reference
    uri_reference = OWLParser::URIReference.new
    assert_instance_of Result::OK, uri_reference.parse("http://localhost.localdomain:3000/pchar;param?query")
    assert_instance_of Result::OK, uri_reference.parse("http://localhost.localdomain")
    result = uri_reference.parse("http://localhost.localdomain")
    assert_instance_of Result::OK, result
    assert_equal Hash[:uri_reference=>"http://localhost.localdomain"], result.value
    assert_equal "", result.input
    result = uri_reference.parse("http://localhost.localdomain)")
    assert_instance_of Result::OK, result
    assert_equal Hash[:uri_reference=>"http://localhost.localdomain"], result.value
    assert_equal ")", result.input
    result = uri_reference.parse("ex:hasMember")
    assert_instance_of Result::OK, result
    assert_equal Hash[:uri_reference => "ex:hasMember"], result.value
    assert_equal "", result.input
    result = uri_reference.parse("")
    assert_instance_of Result::Fail, result
  end



end
