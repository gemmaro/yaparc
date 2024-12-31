# frozen_string_literal: true

require 'test_helper'

class YaparcTest < Test::Unit::TestCase
  include ::Yaparc

  def test_directory_structure
    parser = Yaparc::Seq.new(Yaparc::Many.new(Yaparc::Regex.new(/\A[a-z]/),''),
                             Yaparc::Many.new(Yaparc::Seq.new(Yaparc::Symbol.new('/'), 
                                                              Yaparc::Regex.new(/\A[a-z]*/)) do |_,path|
                                                path
                                              end,'')
                             ) do |head, rest|
      {:head => head,:rest => rest }
    end
    result = parser.parse("root/user")
    assert_instance_of Result::OK,  result
    assert_equal Hash[:head=>"root", :rest=>"user"],  result.value
  end
  
  def test_seq_alt_parse
    parser = Yaparc::Seq.new(Yaparc::Symbol.new('scheme'),
                             Yaparc::Symbol.new(':'),
                             Yaparc::Alt.new(Natural.new,
                                             Identifier.new))
    result = parser.parse("scheme:124")
    assert_instance_of Result::OK,  result
    result = parser.parse("scheme:identifier")
    assert_instance_of Result::OK,  result
  end

  def test_succeed_parse
    parser = ::Yaparc::Succeed.new(1)
    result = parser.parse("abs")
    assert_equal 1, result.value
    assert_equal "abs", result.input
#    assert_equal 1, parser.tree
    result = parser.parse("abs") do |answer|
      answer
    end
    assert_equal 1, result.value
  end

  def test_fail_parse
    parser = ::Yaparc::Fail.new
    result = parser.parse("abc")
    assert_instance_of Result::Fail,  result
  end

  def test_item_parse
    parser = ::Yaparc::Item.new
    result = parser.parse("")
    assert_instance_of Result::Fail,  result
    result = parser.parse("abc")
    assert_equal "a",  result.value
    assert_equal "bc",  result.input
  end

  def test_satisfy_parse
    is_integer = lambda do |i|
      begin
        Integer(i)
        true
      rescue
        false
      end
    end
    parser = Satisfy.new(is_integer)
    result = parser.parse("123")
    assert_equal "1",  result.value
    assert_equal "23",  result.input

    parser = Satisfy.new(is_integer)
    result = parser.parse("abc")
    assert_instance_of Result::Fail,  result

    is_char = lambda do |i|
      begin
        String(i)
        true
      rescue
        false
      end
    end
    parser = Satisfy.new(is_char)
    result = parser.parse("abc")
    assert_equal "a",  result.value
    assert_equal "bc",  result.input
  end

  def test_seq_parse
    parser = Seq.new(Item.new, Item.new) do |item1, item2|
      [item1, item2]
    end
    result = parser.parse("abcdef")
    assert_equal ["a", "b"],  result.value
    assert_equal "cdef",  result.input

    parser = Seq.new(Item.new, Item.new, Item.new) do |item1, item2, item3|
      [item1, item3]
    end
    result = parser.parse("ABCDEF")
    assert_equal ["A", "C"],  result.value
    assert_equal "DEF",  result.input

    parser = Seq.new(Item.new, Item.new, Item.new) do |item1, item2, item3|
      [item2]
    end
    result = parser.parse("ABCDEF")
    assert_equal ["B"],  result.value
    assert_equal "DEF",  result.input

    parser = Seq.new(Digit.new, Many.new(Char.new('a'),''),Many.new(Digit.new,'')) do |digit, _,digits|
      digit + digits
    end
    result = parser.parse("123abc")
    assert_equal "123",  result.value
    assert_equal "abc",  result.input

    parser = Seq.new(
                           Yaparc::Apply.new(Yaparc::Tokenize.new(Digit.new)){|digit| digit}, Many.new(Char.new('a'),''),Many.new(Digit.new,'')) do |digit, _,digits|
      digit + digits
    end
    result = parser.parse("123abc")
    assert_equal "123",  result.value
    assert_equal "abc",  result.input
  end

  def test_seq_parse_without_block
    parser = Seq.new(Item.new, Item.new)
    result = parser.parse("abcdef")
    assert_equal "b",  result.value
    assert_equal "cdef",  result.input
  end

  def test_alt_parse
    parser = Alt.new(Item.new, Succeed.new('d'))
    result = parser.parse("abc")
    assert_equal "a",  result.value
    assert_equal "bc",  result.input

    parser = Alt.new(Fail.new, Succeed.new('d'))
    result = parser.parse("abc")
    assert_equal "d",  result.value
    assert_equal "abc",  result.input

    parser = Alt.new(Fail.new, Fail.new)
    result = parser.parse("abc")
    assert_instance_of Result::Fail,  result

    parser = Alt.new(Natural.new, Ident.new)
    result = parser.parse("abc")
    assert_instance_of Result::OK,  result
    result = parser.parse("124")
    assert_instance_of Result::OK,  result
    result = parser.parse("ABC124")
    assert_instance_of Result::Fail,  result
    result = parser.parse("abc124")
    assert_instance_of Result::OK,  result
    assert_equal 'abc124',  result.value
  end

  def test_apply_parse
    is_digit = lambda {|i| i >= '0' and i <= '9'}
    parser = Apply.new(Satisfy.new(is_digit)) do |digit|
      digit.to_i - '0'.to_i
    end
    result = parser.parse('7')
    assert_equal 7,  result.value
    assert_equal "",  result.input

    parser = Yaparc::Apply.new(Yaparc::Regex.new(/\d+/)) do |match|
      Integer(match)
    end
    result = parser.parse('7')
    assert_equal 7,  result.value
  end

  def test_char_parse
    parser = Char.new("a")
    result = parser.parse("abc")
    assert_equal "a",  result.value
    assert_equal "bc",  result.input

    parser = Char.new("a")
    result = parser.parse("123")
    assert_instance_of Result::Fail,  result

    parser = Char.new("a", false)
    result = parser.parse("a")
    assert_instance_of Result::OK,  result
    result = parser.parse("A")
    assert_instance_of Result::OK,  result
    result = parser.parse("!")
    assert_instance_of Result::Fail,  result
  end

  def test_string_parse
    parser = Yaparc::String.new("abc")
    result = parser.parse("abcdef")
    assert_equal "abc",  result.value
    assert_equal "def",  result.input

    parser = Yaparc::String.new("abc")
    result = parser.parse("ab1234")
    assert_instance_of  Result::Fail,  result

    parser = Yaparc::String.new("abc", false)
    result = parser.parse("abc")
    assert_instance_of  Result::OK,  result
    result = parser.parse("aBc")
    assert_instance_of  Result::OK,  result
  end

  def test_regex_parse
    parser = Regex.new(/\A[a-z]/)
    result = parser.parse("abcdef")
    assert_equal "a",  result.value
    assert_equal "bcdef",  result.input

    parser = Regex.new(/\A[0-9]+/)
    result = parser.parse("1234ab")
    assert_equal "1234",  result.value
    assert_equal "ab",  result.input

    parser = Regex.new(/\A[0-9]+/)
    result = parser.parse("1234ab")
#     result = parser.parse("1234ab") do |match|
#       Integer(match)
#     end
#    assert_equal 1234,  result.value
    assert_equal '1234',  result.value

#     parser = Regex.new(/([0-9]+):([a-z]+)/)
#     result = parser.parse_with_parameter("1234:ab") do |match1, match2|
#       assert_equal 'ab',  match2
#     end

    parser = Regex.new(/([0-9]+):([a-z]+)/) do  |match1, match2|
      [match2,match1]
    end
    result = parser.parse("1234:ab")
    assert_equal ["ab", "1234"],  result.value
  end

  def test_zero_one_parse
    parser = ZeroOne.new(Yaparc::String.new("abc"))
    result = parser.parse("abc  ")
    assert_equal "abc",  result.value
    assert_equal "  ",  result.input
    parser = ZeroOne.new(Yaparc::String.new("abc"))
    result = parser.parse("123")
    assert_equal [],  result.value
    assert_equal "123",  result.input
  end

  def test_many_parse
    is_digit = Satisfy.new(lambda {|i| i >= '0' and i <= '9'})
    parser = Many.new(is_digit,"")
    result = parser.parse("123abc")
    assert_equal "123",  result.value
    assert_equal "abc",  result.input

    result = parser.parse("abcdef")
    assert_equal "",  result.value
    assert_equal "abcdef",  result.input

    parser = Many.new(Alt.new(Ident.new, Nat.new),'')
    result = parser.parse("abc23def")
    assert_equal "abc23def",  result.value

    parser = Many.new(Digit.new,0)
    result = parser.parse("abc")
    assert_instance_of Result::OK,  result
  end

  def test_many_one_parse
    is_digit = Satisfy.new(lambda {|i| i >= '0' and i <= '9'})
    parser = ManyOne.new(is_digit,"")
    result = parser.parse("123abc")
    assert_equal "123",  result.value
    assert_equal "abc",  result.input

    result = parser.parse("abcdef")
    assert_instance_of Result::Fail,  result
    assert_equal "abcdef",  result.input

    parser = ManyOne.new(Char.new('a'),'')
    result = parser.parse("123abc")
    assert_instance_of Result::Fail,  result
  end

  def test_ident
    parser = Ident.new
    result = parser.parse("abc def")
    assert_equal "abc",  result.value
    assert_equal " def",  result.input
  end

  def test_digit
    parser = Digit.new
    result = parser.parse("123 abc")
    assert_equal '1',  result.value
    assert_equal "23 abc",  result.input
  end

  def test_nat
    parser = Nat.new
    result = parser.parse("123 abc")
    assert_equal 123,  result.value
    assert_equal " abc",  result.input
  end

  def test_nat_ident
    parser = Seq.new(Nat.new, Ident.new) do |nat, ident|
      [nat,ident]
    end
    result = parser.parse("123abc")
    assert_equal [123, "abc"],  result.value
    assert_equal "",  result.input
  end

  def test_space
    parser = Space.new
    result = parser.parse("    abc")
    assert_instance_of Result::OK,  result
    assert_equal "abc",  result.input
  end

  def test_whitespace
    parser = WhiteSpace.new
    result = parser.parse(" \n   abc")
    assert_instance_of Result::OK,  result
    assert_equal "abc",  result.input
    snip =<<-SNIP
        
       abc
    SNIP
    result = parser.parse(snip)
    assert_instance_of Result::OK,  result
    assert_equal "abc\n",  result.input
  end

#   def test_token
#     parser = Token.new
#     result = parser.parse(" \n   abc")
#     assert_instance_of Result::OK,  result
#     assert_equal "abc",  result.input
#   end

  def test_tokenize_with_block
    parser = Tokenize.new(Ident.new) do |tokenize|
      tokenize.prefix = Space.new
      tokenize.postfix = Space.new
    end

    result = parser.parse("    abc")
    assert_instance_of Result::OK,  result
    assert_equal "abc",  result.value
    assert_equal "",  result.input

    result = parser.parse(" \n   abc")
    assert_instance_of Result::Fail,  result
    assert_equal "\n   abc",  result.input

    parser = Tokenize.new(Ident.new) do |tokenize|
      tokenize.prefix = WhiteSpace.new
      tokenize.postfix = WhiteSpace.new
    end

    result = parser.parse(" \n   abc")
    assert_instance_of Result::OK,  result
    assert_equal "abc",  result.value
    assert_equal "",  result.input
  end

  def test_tokenize_without_block
    parser = Tokenize.new(Ident.new, :prefix => WhiteSpace.new, :postfix => WhiteSpace.new)

    result = parser.parse("    abc")
    assert_instance_of Result::OK,  result
    assert_equal "abc",  result.value
    assert_equal "",  result.input

    parser = Tokenize.new(Ident.new, :prefix => Space.new, :postfix => Space.new)
    result = parser.parse(" \n   abc")
    assert_instance_of Result::Fail,  result
    assert_equal "\n   abc",  result.input
  end


  def test_natural
    parser = Natural.new
    result = parser.parse(" 1234 ")
    assert_equal 1234,  result.value
    assert_equal "",  result.input
  end

  def test_symbol
    parser = Symbol.new('%')
    result = parser.parse(" % ")
    assert_equal "%",  result.value
    assert_equal "",  result.input
  end

  def test_literal_parser
    parser = Literal.new('%')
    result = parser.parse(" % ")
    assert_equal "%",  result.value
    assert_equal "",  result.input

    parser = Literal.new('vgh', false)
    result = parser.parse(" vgh ")
    assert_instance_of Result::OK,  result
    result = parser.parse(" vgH ")
    assert_instance_of Result::OK,  result
  end
end


class IdentifierParserTest < Test::Unit::TestCase
  include ::Yaparc

  def setup
    @parser = ::Yaparc::Identifier.new
#     @untokenized_parser = ::Yaparc::Identifier.new do |tokenize|
#       tokenize.prefix = Space.new
#       tokenize.postfix = Space.new
#     end
  end

  def test_parse
    result = @parser.parse("abc")
    assert_equal "abc",  result.value
    assert_equal "",  result.input
    result = @parser.parse("    abc ")
    assert_equal "abc",  result.value
    assert_equal "",  result.input
    result = @parser.parse("    _abc ")
    assert_instance_of Result::OK,  result
    result = @parser.parse("    0_abc ")
    assert_instance_of Result::Fail,  result
    result = @parser.parse("    _00abc ")
    assert_instance_of Result::OK,  result
#     result = @untokenized_parser.parse(" \n   abc ")
#     assert_instance_of Result::OK,  result
#     assert_equal "abc",  result.value
#     assert_equal "",  result.input
  end

  def test_parse_with_keyword
    parser_with_keyword = Identifier.new(:exclude => ["abc","efg"])
    result = parser_with_keyword.parse("abc")
    assert_instance_of Result::Fail,  result
    result = parser_with_keyword.parse(" xyz")
    assert_equal "xyz",  result.value
    assert_equal "",  result.input
  end
end
