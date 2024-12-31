require 'test_helper'

module URIParser


  class URIReference # = [ absoluteURI | relativeURI ] [ "#" fragment ]
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        Yaparc::Seq.new(
                        Yaparc::ZeroOne.new(Yaparc::Alt.new(AbsoluteURI.new,
                                                            RelativeURI.new,'')),
                        Yaparc::ZeroOne.new(
                                            Yaparc::Seq.new(Yaparc::Symbol.new('#'),Fragment.new),''))
      end
    end
  end

  class AbsoluteURI # = scheme ":" ( hier_part | opaque_part )
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
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
      @parser = lambda do |input|
        Yaparc::Seq.new(Yaparc::Alt.new(NetPath.new,
                                        AbsPath.new,
                                        RelPath.new),
                        Yaparc::ZeroOne.new(Yaparc::Seq.new(Yaparc::Symbol.new('?'),Query.new),''))
      end
    end
  end

  class HierPart # = ( net_path | abs_path ) [ "?" query ]
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        Yaparc::Seq.new(Yaparc::Alt.new(NetPath.new,
                                        AbsPath.new),
                        Yaparc::ZeroOne.new(Yaparc::Seq.new(Yaparc::Symbol.new('?'),Query.new),''))
      end
    end
  end

  class Path
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        Yaparc::ZeroOne.new(Yaparc::Alt.new(AbsPath.new,
                                            OpaquePart.new),'')
      end
    end
  end

  class OpaquePart # = uric_no_slash *uric
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        Yaparc::Seq.new(UricNoSlash.new,
                        Yaparc::Many.new(Uric.new,''))

      end
    end
  end

  class UricNoSlash #  = unreserved | escaped | ";" | "?" | ":" | "@" | "&" | "=" | "+" | "$" | ","
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        Yaparc::Alt.new(Unreserved.new,
                        Escaped.new,
                        Yaparc::Regex.new(/[;?:@&=+$,]/))
      end
    end
  end

  class NetPath #  = "//" authority [ abs_path ]
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        Yaparc::Seq.new(Yaparc::Symbol.new('//'),
                        Authority.new,
                        Yaparc::ZeroOne.new(AbsPath.new,''))
      end
    end
  end

  class RelPath
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        Yaparc::Seq.new(RelSegment.new,
                        Yaparc::ZeroOne.new(AbsPath.new,''))
      end
    end
  end

  class AbsPath
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        Yaparc::Seq.new(Yaparc::Symbol.new('/'),
                        PathSegments.new)
      end
    end
  end

  class RelSegment
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        Yaparc::ZeroOne.new(Yaparc::Alt.new(Unreserved.new,
                                            Escaped.new,
                                            Yaparc::Regex.new(/[;@&=+$,]/)),'')
      end
    end
  end

  class Scheme  # = alpha *( alpha | digit | "+" | "-" | "." )
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        Yaparc::Seq.new(Alpha.new,
                        Yaparc::Many.new(
                                         Yaparc::Alt.new(
                                                         Alpha.new,
                                                         Digit.new,
                                                         Yaparc::Regex.new(/[+-.]/)),''))
      end
    end
  end

  class Authority
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        Yaparc::Alt.new(Server.new,
                        RegName.new)
      end
    end
  end

  class RegName # 1*( unreserved | escaped | "$" | "," | ";" | ":" | "@" | "&" | "=" | "+" )
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        Yaparc::ManyOne.new(Yaparc::Alt.new(
                                                        Unreserved.new,
                                                        Escaped.new,
                                                        Yaparc::Regex.new(/[$,;:@&=+]/)),'')
      end
    end
  end

  class Server #  = [ [ userinfo "@" ] hostport ]
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        Yaparc::Alt.new(
                        Yaparc::Seq.new(UserInfo.new, Yaparc::Symbol.new('@'),HostPort.new),
                        HostPort.new,
                        Yaparc::Succeed.new(''))
#         Yaparc::ZeroOne.new(
#                                   Yaparc::Seq.new(
#                                                         Yaparc::ZeroOne.new(
#                                                                                   Yaparc::Seq.new(UserInfo.new, Yaparc::Symbol.new('@')),''),
#                                                         HostPort.new,''),'')
      end
    end
  end

  class UserInfo
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        Yaparc::Many.new(Yaparc::Alt.new(Unreserved.new,
                                                     Escaped.new,
                                                     Yaparc::Regex.new(/[;:&=+$,]/)),'')
      end
    end
  end

  class HostPort
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        Yaparc::Seq.new(Host.new,
                              Yaparc::ZeroOne.new(
                                                        Yaparc::Seq.new(Yaparc::Symbol.new(':'),Port.new),''))
      end
    end
  end


  class Host
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        Yaparc::Alt.new(HostName.new,
                              IPv4Address.new)
      end
    end
  end

  class HostName
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        Yaparc::Seq.new(Yaparc::Many.new(Yaparc::Seq.new(DomainLabel.new,Yaparc::Symbol.new('.')),''),
                        TopLabel.new,
                        Yaparc::ZeroOne.new(Yaparc::Symbol.new('.'),''))
      end
    end
  end

  class DomainLabel
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        Yaparc::Alt.new(AlphaNum.new,
                              Yaparc::Seq.new(AlphaNum.new,
                                                    Yaparc::Many.new(
                                                                           Yaparc::Alt.new(AlphaNum.new,Yaparc::Symbol.new('-')),''),
                                                    AlphaNum.new))
      end
    end
  end

  class TopLabel
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        Yaparc::Alt.new(Alpha.new,
                              Yaparc::Seq.new(Alpha.new,
                                                    Yaparc::Many.new(
                                                                           Yaparc::Alt.new(Alpha.new,Yaparc::Symbol.new('-')),''),
                                                    AlphaNum.new))
      end
    end
  end


  class IPv4Address
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        Yaparc::Regex.new(/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/)
#         Yaparc::Seq.new(Yaparc::ManyOne.new(Digit.new,""),
#                               Yaparc::Symbol.new('.'),
#                               Yaparc::ManyOne.new(Digit.new,""),
#                               Yaparc::Symbol.new('.'),
#                               Yaparc::ManyOne.new(Digit.new,""),
#                               Yaparc::Symbol.new('.'),
#                               Yaparc::ManyOne.new(Digit.new,""))
      end
    end
  end

  class Port
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        Yaparc::Many.new(Digit.new,'')
      end
    end
  end

  class PathSegments
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        Yaparc::Seq.new(Segment.new,
                        Yaparc::Many.new(
                                         Yaparc::Seq.new(Yaparc::Symbol.new('/'),
                                                         Segment.new),''))
      end
    end
  end

  class Segment
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        Yaparc::Seq.new(Yaparc::Many.new(Pchar.new,''),
                        Yaparc::Many.new(
                                         Yaparc::Seq.new(Yaparc::Symbol.new(';'),
                                                         Param.new),'')
                        )
      end
    end
  end

  class Param
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        Yaparc::Many.new(Pchar.new,'')
      end
    end
  end

  class Pchar
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        Yaparc::Alt.new(Unreserved.new,Escaped.new,::Yaparc::Regex.new(/[:@&=+$,]/))
      end
    end
  end

  class Query
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        Yaparc::Many.new(Uric.new,'')
      end
    end
  end

  class Fragment
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        Yaparc::Many.new(Uric.new,'')
      end
    end
  end

  class Uric
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        Yaparc::Alt.new(Reserved.new,Unreserved.new,Escaped.new)
      end
    end
  end

  class Reserved
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        ::Yaparc::Regex.new(/[;\/?\:@&=+$,]/)
      end
    end
  end

  class Unreserved
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        Yaparc::Alt.new(AlphaNum.new, Mark.new)
      end
    end
  end

  class Mark
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        ::Yaparc::Regex.new(/[-_.!~*'()]/)
      end
    end
  end

  class Escaped
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        ::Yaparc::Seq.new(::Yaparc::Symbol.new('%'),
                          Hex.new,
                          Hex.new)
      end
    end
  end

  class Hex
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        ::Yaparc::Regex.new(/[0-9A-Fa-f]/)
      end
    end
  end

  class AlphaNum
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        Yaparc::Alt.new(Alpha.new, Digit.new)
      end
    end
  end

  class Alpha
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        Yaparc::Alt.new(LowAlpha.new, UpAlpha.new)
      end
    end
  end

  class LowAlpha
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        ::Yaparc::Regex.new(/[a-z]/)
      end
    end
  end

  class UpAlpha
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        ::Yaparc::Regex.new(/[A-Z]/)
      end
    end
  end

  class Digit
    include Yaparc::Parsable
    def initialize
      @parser = lambda do |input|
        ::Yaparc::Regex.new(/[0-9]/)
      end
    end
  end
end

class UriTest < Test::Unit::TestCase
  include ::Yaparc


  def test_uri_reference
    uri_reference = URIParser::URIReference.new
    assert_instance_of Result::OK, uri_reference.parse("http://localhost.localdomain:3000/pchar;param")
    assert_instance_of Result::OK, uri_reference.parse("ftp://localhost.localdomain/pchar;param/pchar;param")
    assert_instance_of Result::OK, uri_reference.parse("http://localhost.localdomain:3000/pchar;param?query")
    assert_instance_of Result::OK, uri_reference.parse("ftp://localhost.localdomain/pchar;param/pchar;param?query")

  end

  def test_absolute_uri   # = scheme ":" ( hier_part | opaque_part )
    absolute_uri = URIParser::AbsoluteURI.new
    assert_instance_of Result::OK, URIParser::HierPart.new.parse("//localhost.localdomain:3000/pchar;param")

    omit
    assert_instance_of Result::OK, absolute_uri.parse("http://localhost.localdomain:3000/pchar;param")

#     assert_instance_of Result::OK, absolute_uri.parse("ftp://localhost.localdomain/pchar;param/pchar;param")
#     assert_instance_of Result::OK, absolute_uri.parse("http://localhost.localdomain:3000/pchar;param?query")
#     assert_instance_of Result::OK, absolute_uri.parse("ftp://localhost.localdomain/pchar;param/pchar;param?query")
  end

  def test_relative_uri # ( net_path | abs_path | rel_path ) [ "?" query ]
    relative_uri = URIParser::RelativeURI.new
    assert_instance_of Result::OK, relative_uri.parse("//localhost.localdomain:3000/pchar;param")
    assert_instance_of Result::OK, relative_uri.parse("//localhost.localdomain/pchar;param/pchar;param")
    assert_instance_of Result::OK, relative_uri.parse("//localhost.localdomain:3000/pchar;param?query")
    assert_instance_of Result::OK, relative_uri.parse("//localhost.localdomain/pchar;param/pchar;param?query")
  end

  def test_hier_part # ( net_path | abs_path ) [ "?" query ]
    hier_part = URIParser::HierPart.new
    assert_instance_of Result::OK, hier_part.parse("//localhost.localdomain:3000/pchar;param")
    assert_instance_of Result::OK, hier_part.parse("//localhost.localdomain/pchar;param/pchar;param")
    assert_instance_of Result::OK, hier_part.parse("//localhost.localdomain:3000/pchar;param?query")
    assert_instance_of Result::OK, hier_part.parse("//localhost.localdomain/pchar;param/pchar;param?query")
  end

  def test_path
    path = URIParser::Path.new
    assert_instance_of URIParser::Path, path
  end

  def test_opaque_part
    opaque_part = URIParser::OpaquePart.new
    assert_instance_of URIParser::OpaquePart, opaque_part
  end

  def test_uric_no_slash
    uric_no_slash = URIParser::UricNoSlash.new
    assert_instance_of URIParser::UricNoSlash, uric_no_slash
  end


  def test_net_path
    net_path = URIParser::NetPath.new
    assert_instance_of Result::OK, net_path.parse("//localhost.localdomain:3000/pchar;param")
    assert_instance_of Result::OK, net_path.parse("//localhost.localdomain/pchar;param/pchar;param")
  end

  def test_rel_path
    rel_path = URIParser::RelPath.new
    assert_instance_of Result::OK, rel_path.parse("pchar;param")
    assert_instance_of Result::OK, rel_path.parse("pchar;param/pchar;param")
  end

  def test_abs_path
    abs_path = URIParser::AbsPath.new
    assert_instance_of Result::OK, abs_path.parse("/pchar;param")
    assert_instance_of Result::OK, abs_path.parse("/pchar;param/pchar;param")
  end

  def test_rel_segment
    rel_segment = URIParser::RelSegment.new
    assert_instance_of Result::OK, rel_segment.parse("_")
    assert_instance_of Result::OK, rel_segment.parse("'")
    assert_instance_of Result::OK, rel_segment.parse("(")
    assert_instance_of Result::OK, rel_segment.parse("z")
    assert_instance_of Result::OK, rel_segment.parse(";")
  end

  def test_scheme
    scheme = URIParser::Scheme.new
    assert_instance_of Result::OK, scheme.parse("http")
    assert_instance_of Result::OK, scheme.parse("ftp")
  end

  def test_authority
    authority = URIParser::Authority.new
    assert_instance_of Result::OK, authority.parse("a")
    assert_instance_of Result::OK, authority.parse("localhost")
    assert_instance_of Result::OK, authority.parse("localhost.localdomain")
    assert_instance_of Result::OK, authority.parse("192.168.0.2:8080")
    assert_instance_of Result::OK, authority.parse("localhost.localdomain:3000")
    assert_instance_of Result::OK, authority.parse("192.168.0.2")
    assert_instance_of Result::OK, authority.parse("emile@localhost.localdomain:3000")
    assert_instance_of Result::OK, authority.parse("emile@192.168.0.2")
    assert_instance_of Result::OK, authority.parse("192")
    assert_instance_of Result::OK, authority.parse("_")
    assert_instance_of Result::OK, authority.parse("'")
    assert_instance_of Result::OK, authority.parse("(")
    assert_instance_of Result::OK, authority.parse("z")
    assert_instance_of Result::OK, authority.parse(";")
  end

  def test_reg_name
    reg_name = URIParser::RegName.new
    assert_instance_of Result::OK, reg_name.parse("_")
    assert_instance_of Result::OK, reg_name.parse("'")
    assert_instance_of Result::OK, reg_name.parse("(")
    assert_instance_of Result::OK, reg_name.parse("z")
    assert_instance_of Result::OK, reg_name.parse(";")
  end


  def test_server
    server = URIParser::Server.new
    assert_instance_of Result::OK, server.parse("a")
    assert_instance_of Result::OK, server.parse("localhost")
    assert_instance_of Result::OK, server.parse("localhost.localdomain")
    assert_instance_of Result::OK, server.parse("192.168.0.2:8080")
    assert_instance_of Result::OK, server.parse("localhost.localdomain:3000")
    assert_instance_of Result::OK, server.parse("192.168.0.2")
    assert_instance_of Result::OK, server.parse("emile@localhost.localdomain:3000")
    assert_instance_of Result::OK, server.parse("emile@192.168.0.2")
    assert_instance_of Result::OK, server.parse("192")
  end

  def test_user_info
    user_info = URIParser::UserInfo.new
    assert_instance_of URIParser::UserInfo, user_info
  end

  def test_host_port
    host_port = URIParser::HostPort.new
    assert_instance_of Result::OK, host_port.parse("a")
    assert_instance_of Result::OK, host_port.parse("localhost")
    assert_instance_of Result::OK, host_port.parse("localhost.localdomain")
    assert_instance_of Result::OK, host_port.parse("192.168.0.2:8080")
    assert_instance_of Result::OK, host_port.parse("localhost.localdomain:3000")
    assert_instance_of Result::OK, host_port.parse("192.168.0.2")
    assert_instance_of Result::Fail, host_port.parse("192")
  end

  def test_host
    host = URIParser::Host.new
    assert_instance_of Result::OK, host.parse("a")
    assert_instance_of Result::OK, host.parse("localhost")
    assert_instance_of Result::OK, host.parse("localhost.localdomain")
    assert_instance_of Result::OK, host.parse("192.168.0.2")
    assert_instance_of Result::Fail, host.parse("192")
  end

  def test_host_name
    host_name = URIParser::HostName.new
    assert_instance_of Result::OK, host_name.parse("a")
    assert_instance_of Result::OK, host_name.parse("localhost")
    assert_instance_of Result::OK, host_name.parse("localhost.localdomain")
    assert_instance_of Result::Fail, host_name.parse("192")
  end

  def test_domain_label
    domain_label = URIParser::DomainLabel.new
    assert_instance_of Result::OK, domain_label.parse("a")
    assert_instance_of Result::OK, domain_label.parse("localhost")
    assert_instance_of Result::OK, domain_label.parse("192")
  end

  def test_top_label
    top_label = URIParser::TopLabel.new
    assert_instance_of Result::OK, top_label.parse("a")
    assert_instance_of Result::OK, top_label.parse("localhost")
    assert_instance_of Result::Fail, top_label.parse("192")
  end

  def test_ipv4address
    ipv4address = URIParser::IPv4Address.new
    assert_instance_of Result::OK, ipv4address.parse("192.168.0.1")
    assert_instance_of Result::Fail, ipv4address.parse("8080")
  end

  def test_port
    port = URIParser::Port.new
    assert_instance_of Result::OK, port.parse("8080")
    assert_instance_of Result::OK, port.parse("pchar;param/pchar;param")
  end

  def test_path_segment
    path_segments = URIParser::PathSegments.new
    assert_instance_of Result::OK, path_segments.parse("pchar;param")
    assert_instance_of Result::OK, path_segments.parse("pchar;param/pchar;param")
  end

  def test_segment
    segment = URIParser::Segment.new
    assert_instance_of Result::OK, segment.parse("pchar;param")
  end

  def test_param
    param = URIParser::Param.new
    assert_instance_of Result::OK, param.parse("_")
    assert_instance_of Result::OK, param.parse("'")
    assert_instance_of Result::OK, param.parse("(")
    assert_instance_of Result::OK, param.parse("z")
    assert_instance_of Result::OK, param.parse(";")
  end

  def test_pchar
    pchar = URIParser::Pchar.new
    assert_instance_of Result::OK, pchar.parse("_")
    assert_instance_of Result::OK, pchar.parse("'")
    assert_instance_of Result::OK, pchar.parse("(")
    assert_instance_of Result::OK, pchar.parse("z")
    assert_instance_of Result::Fail, pchar.parse(";")
  end

  def test_fragment
    fragment = URIParser::Fragment.new
    assert_instance_of Result::OK, fragment.parse(";")
    assert_instance_of Result::OK, fragment.parse("_")
    assert_instance_of Result::OK, fragment.parse("'")
    assert_instance_of Result::OK, fragment.parse("(")
    assert_instance_of Result::OK, fragment.parse("z")
  end

  def test_uric
    uric = URIParser::Uric.new
    assert_instance_of Result::OK, uric.parse(";")
    assert_instance_of Result::OK, uric.parse("_")
    assert_instance_of Result::OK, uric.parse("'")
    assert_instance_of Result::OK, uric.parse("(")
    assert_instance_of Result::OK, uric.parse("z")
  end

  def test_reserved
    reserved = URIParser::Reserved.new
    assert_instance_of Result::OK, reserved.parse(";")
    assert_instance_of Result::Fail, reserved.parse("_")
    assert_instance_of Result::Fail, reserved.parse("'")
    assert_instance_of Result::Fail, reserved.parse("(")
    assert_instance_of Result::Fail, reserved.parse("z")
  end

  def test_unreserved
    unreserved = URIParser::Unreserved.new
    assert_instance_of Result::OK, unreserved.parse("_")
    assert_instance_of Result::OK, unreserved.parse("'")
    assert_instance_of Result::OK, unreserved.parse("(")
    assert_instance_of Result::OK, unreserved.parse("z")
    assert_instance_of Result::Fail, unreserved.parse(";")
  end

  def test_mark
    mark = URIParser::Mark.new
    assert_instance_of Result::OK, mark.parse("_")
    assert_instance_of Result::OK, mark.parse("'")
    assert_instance_of Result::OK, mark.parse("(")
    assert_instance_of Result::Fail, mark.parse("z")
  end

  def test_hex
    hex = URIParser::Hex.new
    assert_instance_of Result::OK, hex.parse("b")
    assert_instance_of Result::OK, hex.parse("A")
    assert_instance_of Result::OK, hex.parse("0")
    assert_instance_of Result::Fail, hex.parse("z")
  end

  def test_escaped
    escaped = URIParser::Escaped.new
    assert_instance_of Result::OK, escaped.parse("%aA")
    assert_instance_of Result::Fail, escaped.parse("0")
    assert_instance_of Result::Fail, escaped.parse("z")
  end

  def test_alpha
    alpha = URIParser::Alpha.new
    assert_instance_of Result::OK, alpha.parse("b")
    assert_instance_of Result::OK, alpha.parse("A")
    assert_instance_of Result::Fail, alpha.parse("0")
  end

  def test_alpha_num
    alpha_num = URIParser::AlphaNum.new
    assert_instance_of Result::OK, alpha_num.parse("b")
    assert_instance_of Result::OK, alpha_num.parse("A")
    assert_instance_of Result::OK, alpha_num.parse("0")
  end

  def test_low_alpha
    low_alpha = URIParser::LowAlpha.new
    assert_instance_of Result::OK, low_alpha.parse("b")
    assert_instance_of Result::Fail, low_alpha.parse("A")
    assert_instance_of Result::Fail, low_alpha.parse("0")
  end

  def test_up_alpha
    up_alpha = URIParser::UpAlpha.new
    assert_instance_of Result::OK, up_alpha.parse("A")
    assert_instance_of Result::Fail, up_alpha.parse("b")
    assert_instance_of Result::Fail, up_alpha.parse("0")
  end

  def test_digit
    digit = URIParser::Digit.new
    assert_instance_of Result::OK, digit.parse("1")
    assert_instance_of Result::OK, digit.parse("0")
    assert_instance_of Result::OK, digit.parse("2")
    assert_instance_of Result::OK, digit.parse("9")
    assert_instance_of Result::Fail, digit.parse("a")
  end


end
