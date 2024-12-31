module URIParser
  class URIReference
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |_input|
        Yaparc::Seq.new(
          Yaparc::ZeroOne.new(Yaparc::Alt.new(AbsoluteURI.new,
                                              RelativeURI.new, '')),
          Yaparc::ZeroOne.new(
            Yaparc::Seq.new(Yaparc::Symbol.new('#'), Fragment.new), ''
          )
        )
      end
    end
  end

  class AbsoluteURI
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |_input|
        Yaparc::Seq.new(Scheme.new,
                        Yaparc::Symbol.new(':'),
                        Yaparc::Alt.new(HierPart.new,
                                        OpaquePart.new))
      end
    end
  end

  class RelativeURI
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |_input|
        Yaparc::Seq.new(Yaparc::Alt.new(NetPath.new,
                                        AbsPath.new,
                                        RelPath.new),
                        Yaparc::ZeroOne.new(Yaparc::Seq.new(Yaparc::Symbol.new('?'), Query.new), ''))
      end
    end
  end

  class HierPart
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |_input|
        Yaparc::Seq.new(Yaparc::Alt.new(NetPath.new,
                                        AbsPath.new),
                        Yaparc::ZeroOne.new(Yaparc::Seq.new(Yaparc::Symbol.new('?'), Query.new), ''))
      end
    end
  end

  class Path
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |_input|
        Yaparc::ZeroOne.new(Yaparc::Alt.new(AbsPath.new,
                                            OpaquePart.new), '')
      end
    end
  end

  class OpaquePart
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |_input|
        Yaparc::Seq.new(UricNoSlash.new,
                        Yaparc::Many.new(Uric.new, ''))
      end
    end
  end

  class UricNoSlash
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |_input|
        Yaparc::Alt.new(Unreserved.new,
                        Escaped.new,
                        Yaparc::Regex.new(/[;?:@&=+$,]/))
      end
    end
  end

  class NetPath
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |_input|
        Yaparc::Seq.new(Yaparc::Symbol.new('//'),
                        Authority.new,
                        Yaparc::ZeroOne.new(AbsPath.new, ''))
      end
    end
  end

  class RelPath
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |_input|
        Yaparc::Seq.new(RelSegment.new,
                        Yaparc::ZeroOne.new(AbsPath.new, ''))
      end
    end
  end

  class AbsPath
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |_input|
        Yaparc::Seq.new(Yaparc::Symbol.new('/'),
                        PathSegments.new)
      end
    end
  end

  class RelSegment
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |_input|
        Yaparc::ZeroOne.new(Yaparc::Alt.new(Unreserved.new,
                                            Escaped.new,
                                            Yaparc::Regex.new(/[;@&=+$,]/)), '')
      end
    end
  end

  class Scheme
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |_input|
        Yaparc::Seq.new(Alpha.new,
                        Yaparc::Many.new(
                          Yaparc::Alt.new(
                            Alpha.new,
                            Digit.new,
                            Yaparc::Regex.new(/[+-.]/)
                          ), ''
                        ))
      end
    end
  end

  class Authority
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |_input|
        Yaparc::Alt.new(Server.new,
                        RegName.new)
      end
    end
  end

  class RegName
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |_input|
        Yaparc::ManyOne.new(Yaparc::Alt.new(
                              Unreserved.new,
                              Escaped.new,
                              Yaparc::Regex.new(/[$,;:@&=+]/)
                            ), '')
      end
    end
  end

  class Server
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |_input|
        Yaparc::Alt.new(
          Yaparc::Seq.new(UserInfo.new, Yaparc::Symbol.new('@'), HostPort.new),
          HostPort.new,
          Yaparc::Succeed.new('')
        )
      end
    end
  end

  class UserInfo
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |_input|
        Yaparc::Many.new(Yaparc::Alt.new(Unreserved.new,
                                         Escaped.new,
                                         Yaparc::Regex.new(/[;:&=+$,]/)), '')
      end
    end
  end

  class HostPort
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |_input|
        Yaparc::Seq.new(Host.new,
                        Yaparc::ZeroOne.new(
                          Yaparc::Seq.new(Yaparc::Symbol.new(':'), Port.new), ''
                        ))
      end
    end
  end

  class Host
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |_input|
        Yaparc::Alt.new(HostName.new,
                        IPv4Address.new)
      end
    end
  end

  class HostName
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |_input|
        Yaparc::Seq.new(Yaparc::Many.new(Yaparc::Seq.new(DomainLabel.new, Yaparc::Symbol.new('.')), ''),
                        TopLabel.new,
                        Yaparc::ZeroOne.new(Yaparc::Symbol.new('.'), ''))
      end
    end
  end

  class DomainLabel
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |_input|
        Yaparc::Alt.new(AlphaNum.new,
                        Yaparc::Seq.new(AlphaNum.new,
                                        Yaparc::Many.new(
                                          Yaparc::Alt.new(AlphaNum.new,
                                                          Yaparc::Symbol.new('-')), ''
                                        ),
                                        AlphaNum.new))
      end
    end
  end

  class TopLabel
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |_input|
        Yaparc::Alt.new(Alpha.new,
                        Yaparc::Seq.new(Alpha.new,
                                        Yaparc::Many.new(
                                          Yaparc::Alt.new(Alpha.new,
                                                          Yaparc::Symbol.new('-')), ''
                                        ),
                                        AlphaNum.new))
      end
    end
  end

  class IPv4Address
    include Yaparc::Parsable
    def initialize
      @parser = proc { Yaparc::Regex.new(/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/) }
    end
  end

  class Port
    include Yaparc::Parsable
    def initialize
      @parser = proc { Yaparc::Many.new(Digit.new, '') }
    end
  end

  class PathSegments
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |_input|
        Yaparc::Seq.new(Segment.new,
                        Yaparc::Many.new(
                          Yaparc::Seq.new(Yaparc::Symbol.new('/'),
                                          Segment.new), ''
                        ))
      end
    end
  end

  class Segment
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |_input|
        Yaparc::Seq.new(Yaparc::Many.new(Pchar.new, ''),
                        Yaparc::Many.new(
                          Yaparc::Seq.new(Yaparc::Symbol.new(';'),
                                          Param.new), ''
                        ))
      end
    end
  end

  class Param
    include Yaparc::Parsable
    def initialize
      @parser = proc { Yaparc::Many.new(Pchar.new, '') }
    end
  end

  class Pchar
    include Yaparc::Parsable
    def initialize
      @parser = proc {
        Yaparc::Alt.new(Unreserved.new, Escaped.new, ::Yaparc::Regex.new(/[:@&=+$,]/))
      }
    end
  end

  class Query
    include Yaparc::Parsable

    def initialize
      @parser = proc { Yaparc::Many.new(Uric.new, '') }
    end
  end

  class Fragment
    include Yaparc::Parsable

    def initialize
      @parser = proc { Yaparc::Many.new(Uric.new, '') }
    end
  end

  class Uric
    include Yaparc::Parsable

    def initialize
      @parser = proc {
        Yaparc::Alt.new(Reserved.new, Unreserved.new, Escaped.new)
      }
    end
  end

  class Reserved
    include Yaparc::Parsable

    def initialize
      @parser = proc { ::Yaparc::Regex.new(%r{[;/?:@&=+$,]}) }
    end
  end

  class Unreserved
    include Yaparc::Parsable

    def initialize
      @parser = proc { Yaparc::Alt.new(AlphaNum.new, Mark.new) }
    end
  end

  class Mark
    include Yaparc::Parsable

    def initialize
      @parser = proc { ::Yaparc::Regex.new(/[-_.!~*'()]/) }
    end
  end

  class Escaped
    include Yaparc::Parsable

    def initialize
      @parser = proc {
        ::Yaparc::Seq.new(::Yaparc::Symbol.new('%'),
                          Hex.new,
                          Hex.new)
      }
    end
  end

  class Hex
    include Yaparc::Parsable

    def initialize
      @parser = proc { ::Yaparc::Regex.new(/[0-9A-Fa-f]/) }
    end
  end

  class AlphaNum
    include Yaparc::Parsable

    def initialize
      @parser = proc { Yaparc::Alt.new(Alpha.new, Digit.new) }
    end
  end

  class Alpha
    include Yaparc::Parsable

    def initialize
      @parser = proc { Yaparc::Alt.new(LowAlpha.new, UpAlpha.new) }
    end
  end

  class LowAlpha
    include Yaparc::Parsable

    def initialize
      @parser = proc { ::Yaparc::Regex.new(/[a-z]/) }
    end
  end

  class UpAlpha
    include Yaparc::Parsable

    def initialize
      @parser = proc { ::Yaparc::Regex.new(/[A-Z]/) }
    end
  end

  class Digit
    include Yaparc::Parsable

    def initialize
      @parser = proc { ::Yaparc::Regex.new(/[0-9]/) }
    end
  end
end
