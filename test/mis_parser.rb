module MISParser
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

  class DecimalMultiplePrefix
    include Yaparc::Parsable

    def initialize
      @parser = lambda do |_input|
        Yaparc::Regex.new(/\AE|G|M|P|T|Y|Z|da|h|k/)
      end
    end
  end

  class DecimalSubmultiplePrefix
    include Yaparc::Parsable

    def initialize
      @parser = lambda do |_input|
        Yaparc::Regex.new(/\A[acdfmnpuyz]/)
      end
    end
  end

  class BinaryPrefix
    include Yaparc::Parsable

    def initialize
      @parser = lambda do |_input|
        Yaparc::Regex.new(/\AEi|Gi|Ki|Mi|Pi|Ti/)
      end
    end
  end

  class UnitPSymbol
    include Yaparc::Parsable

    def initialize
      @parser = lambda do |_input|
        Yaparc::Regex.new(/\ABd|B|r|t/)
      end
    end
  end

  class UnitNSymbol
    include Yaparc::Parsable

    def initialize
      @parser = lambda do |_input|
        Yaparc::Regex.new(/\AL|Np|o|oC|rad|sr/)
      end
    end
  end

  class UnitBSymbol
    include Yaparc::Parsable

    def initialize
      @parser = lambda do |_input|
        Yaparc::Regex.new(/\AA|Bq|C|F|Gy|H|Hz|J|K|N|Ohm|Pa|S|Sv|T|V|W|Wb|bit|cd|eV|g|kat|lm|lx|m|mol|s/)
      end
    end
  end

  class UnitSymbol
    include Yaparc::Parsable

    def initialize
      @parser = lambda do |_input|
        Yaparc::Regex.new(/\Ad|dB|h|min|u/)
      end
    end
  end

  class Real
    include Yaparc::Parsable

    def initialize
      @parser = lambda do |_input|
        Yaparc::Seq.new(Yaparc::ZeroOne.new(Yaparc::Literal.new('-'), ''), Ureal.new)
      end
    end
  end

  class Ureal
    include Yaparc::Parsable

    def initialize
      @parser = lambda do |_input|
        Yaparc::Seq.new(NumericalValue.new, Yaparc::ZeroOne.new(Suffix.new, ''))
      end
    end
  end

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

  class Dot
    include Yaparc::Parsable

    def initialize
      @parser = lambda do |_input|
        Yaparc::Regex.new(/\A[.,]/)
      end
    end
  end

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

  class Uinteger
    include Yaparc::Parsable

    def initialize
      @parser = lambda do |_input|
        Yaparc::ManyOne.new(Digit.new, '')
      end
    end
  end

  class ExponentMarker
    include Yaparc::Parsable

    def initialize
      @parser = lambda do |_input|
        Yaparc::Regex.new(/\A[eE]/)
      end
    end
  end

  class Digit
    include Yaparc::Parsable

    def initialize
      @parser = lambda do |_input|
        Yaparc::Regex.new(/\A\d/)
      end
    end
  end
end
