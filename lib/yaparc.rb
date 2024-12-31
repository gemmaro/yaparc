# frozen_string_literal: true

module Yaparc
  VERSION = "0.3.0"

  begin
    base = Class.new do
      attr :input, :value

      def initialize(input:, value: nil)
        @input = input
        @value = value
      end
    end

    OK = Class.new(base)
    Fail = Class.new(base)
    Error = Class.new(base)
  end

  module Parsable
    IS_LOWER      = lambda {|c| c >= 'a' and c <= 'z'}
    IS_ALPHANUM   = lambda {|c| (c >= 'a' and c <= 'z') or (c >= '0' and c <= '9')}
    IS_DIGIT      = lambda {|i| i >= '0' and i <= '9'}
    IS_SPACE      = lambda {|i| i == ' '}
    IS_WHITESPACE = lambda {|i| i == ' ' or i == "\n" or i == "\t"}
    IS_CR         = lambda {|i| i == "\n"}

    def parse(input)
      result = @parser.call(input)

      if result.respond_to?(:parse)
        result.parse(input)
      else
        result
      end
    end
  end

  class Succeed
    include Parsable

    attr_reader :remaining

    def initialize(value, remaining = nil)
      @parser = lambda { |input| OK.new(value:, input:) }
      @remaining = remaining
    end
  end

  class FailParser
    include Parsable

    def initialize
      @parser = lambda { |input| Fail.new(input:) }
    end
  end

  class Item
    include Parsable

    def initialize
      @parser = lambda do |input|
        if input.nil? || input.empty?
          Fail.new(input:)
        else
          OK.new(value: input[0], input: input[1..])
        end
      end
    end
  end

  class ZeroOne
    include Parsable

    def initialize(parser, identity = [])
      @parser = lambda do |input|
        case (result = parser.parse(input))
        in Fail
          OK.new(:value => identity, input:)
        in Error
          Error.new(:value => result.value, :input => result.input)
        in OK
          result
        end
      end
    end
  end

  class Satisfy
    include Parsable

    def initialize(predicate)
      @parser = lambda do |input|
        result = Item.new.parse(input)

        if result.instance_of?(OK) && predicate.call(result.value)
          Succeed.new(result.value, result.input)
        else
          FailParser.new
        end
      end
    end

    def parse(input)
      case parser = @parser.call(input)
      in Succeed
        parser.parse(parser.remaining)
      in FailParser
        parser.parse(input)
      end
    end
  end


  class NoFail
    # hutton92:_higher_order_funct_parsin,p.19
    include Parsable

    def initialize(parser, &block)
      @parser = lambda do |input|
        result = parser.parse(input)
        if result.instance_of?(Fail)
          Error.new(:value => result.value, :input => result.input)
        else
          Succeed.new(result.value)
        end
      end
    end
  end # of NoFail


  class Seq
    include Parsable

    def initialize(*parsers, &block)
      @parser = lambda do |input|
        args = []
        initial_result = OK.new(:input => input)
        final_result = parsers.inject(initial_result) do |subsequent, parser|
          result = parser.parse(subsequent.input)
          if result.instance_of?(Fail)
            break Fail.new(:input => subsequent.input)
          else
            args << result.value
            result
          end
        end

        case final_result
        in Fail
          Fail.new(:input => final_result.input)
        in OK
          final_value = if block_given?
                          yield(*args)
                        else
                          args.last
                        end
          OK.new(:value => final_value, :input => final_result.input)
        end
      end
    end # of initialize
  end # of Seq

  class Alt
    include Parsable
    def initialize(*parsers)
      @parser = lambda do |input|
        final_result = Fail.new(:input => input)
        parsers.each do |parser|
          case result = parser.parse(input)
          in Fail
            next
          in OK
            break final_result = result
          end
        end
        final_result
      end
    end
  end

  class Apply
    include Parsable

    def initialize(parser, &block)
      @parser = lambda do |input|
        result = parser.parse(input)
        if result.instance_of?(OK)
          Succeed.new(yield(result.value)).parse(result.input)
        else
          FailParser.new.parse(input)
        end
      end
    end # of initialize
  end # of Apply


  class String
    include Parsable

    def initialize(string, case_sensitive = true)
      @parser = lambda do |input|
        result = Item.new.parse(string)
        if result.instance_of?(OK)
          Seq.new(
                  Char.new(result.value, case_sensitive),
                  Yaparc::String.new(result.input, case_sensitive),
                  Succeed.new(result.value + result.input)
#                  ) do |char_result, string_result, succeed_result|
                  ) do |_, _, succeed_result|
            succeed_result
          end
        else
          Succeed.new(result)
        end
      end
    end
  end

  class Regex
    include Parsable

    def initialize(regex, &block)
      @regex = regex
      @parser = lambda do |input|
        if match = Regexp.new(regex).match(input)
          if block_given?
            Succeed.new(yield(*match.to_a[1..match.to_a.length])).parse(match.post_match)
          else
            OK.new(:value => match[0], :input => match.post_match)
          end
        else
          Fail.new(:input => input)
        end
      end
    end
  end

  # permits zero or more applications of parser.
  class Many
    include Parsable

    def initialize(parser, identity = [])
      @parser = lambda do |input|
        Alt.new(ManyOne.new(parser, identity), Succeed.new(identity))
      end
    end
  end

  # requires at least one successfull application of parser.
  class ManyOne
    include Parsable

    def initialize(parser, identity = [])
      @parser = lambda do |input|
        Seq.new(parser, Many.new(parser, identity)) do |head, tail|
          case head
          when ::String, ::Array, ::Integer
            head + tail
          when ::Hash
            head.merge(tail)
          else
            if tail.nil?
              head
            else
              [head] + tail
            end
          end
        end
      end
    end
  end

  class Space
    include Parsable
    def initialize
      @parser = lambda do |input|
        #Many.new(Satisfy.new(IS_SPACE),"")
        Regex.new(/\A[ ]*/)
      end
    end
  end

  class CR
    include Parsable
    def initialize
      @parser = lambda do |input|
        Regex.new(/\A[ \t]+[\n][ \t\n]+/)
      end
    end
  end

  class WhiteSpace
    include Parsable

    def initialize
      @parser = lambda do |input|
        #Many.new(Satisfy.new(IS_WHITESPACE),'')
        Regex.new(/\A[\t\n ]*/)
      end
    end
  end

  class Tokenize
    include Parsable

    attr_accessor :prefix, :postfix

    def initialize(parser, prefix: nil, postfix: nil, &block)
      @parser = lambda do |input|
        @prefix = prefix || WhiteSpace.new
        @postfix = postfix || WhiteSpace.new
        if block_given?
          yield self
          Seq.new(@prefix, parser, @postfix) do |_, vs, _|
            vs
          end
        else
          Seq.new(@prefix, parser, @postfix) do |_, vs, _|
            vs
          end
        end
      end
    end
  end

  class Literal
    include Parsable

    def initialize(literal, case_sensitive = true)
      @parser =  lambda do |input|
        Tokenize.new(Yaparc::String.new(literal, case_sensitive))
      end
    end
  end

  # Refer to http://www.cs.nott.ac.uk/~gmh/monparsing.pdf, p.23
  class Identifier
    include Yaparc::Parsable

    IDENTIFIER_REGEX = /\A[a-zA-Z_]+[a-zA-Z0-9_]*/

    def initialize(regex: nil, exclude: nil)
      identifier_regex = if regex
                           ::Yaparc::Regex.new(regex)
                         else
                           ::Yaparc::Regex.new(IDENTIFIER_REGEX)
                         end

      tokenizer = Tokenize.new(identifier_regex)

      if exclude
        @parser = lambda do |input|
          keyword_parsers = exclude.map {|keyword| Yaparc::String.new(keyword)}

          case result = Yaparc::Alt.new(*keyword_parsers).parse(input)
          when Yaparc::OK
            Yaparc::FailParser.new
          else # Fail or Error
            tokenizer
          end
        end
      else
        @parser = lambda do |input|
          tokenizer
        end
      end
    end
  end

#   class Identifier
#     include Yaparc::Parsable
#     @@identifier_regex = ::Yaparc::Regex.new(/\A[a-zA-Z_]+[a-zA-Z0-9_]*/)

#     def initialize(*keywords)
# #    def initialize(*keywords, &block)
#       if keywords == []
#         @parser = lambda do |input|
#           Tokenize.new(@@identifier_regex)
# #           if block_given?
# #             tokenize = Tokenize.new(@@identifier_regex)
# #             yield tokenize
# #             tokenize
# #           else
# #             Tokenize.new(@@identifier_regex)
# #           end
#         end
#       else
#         @parser = lambda do |input|
#           keyword_parsers = keywords.map {|keyword| Yaparc::String.new(keyword)}

#           case result = Yaparc::Alt.new(*keyword_parsers).parse(input)
#           when Yaparc::OK
#             Yaparc::Fail.new
#           else # Fail or Error
#             Tokenize.new(@@identifier_regex)
#           end
#         end
#       end
#     end
#   end

  class Char
    include Parsable

    def initialize(char, case_sensitive = true)
      if case_sensitive
        equal_char = lambda {|i| i == char}
      else # in case of case-insentive
        equal_char = lambda {|i| i.casecmp(char) == 0}
      end
      @parser =  lambda do |input|
        Satisfy.new(equal_char)
      end
    end
  end

  class Ident
    include Parsable
    def initialize
      @parser = lambda do |input|
        Seq.new(
                Satisfy.new(IS_LOWER),
                Many.new(Satisfy.new(IS_ALPHANUM),"")
                ) do |head, tail|
          head + tail
        end
      end
    end
  end

  class Digit
    include Parsable
    def initialize
      @parser = lambda do |input|
        Satisfy.new(IS_DIGIT)
      end
    end
  end

  class Nat
    include Parsable
    def initialize
      @parser = lambda do |input|
        Seq.new(ManyOne.new(Digit.new,'')) do |vs|
          if vs == ""
            0 #            vs
          else
            vs.to_i
          end
        end
      end
    end
  end


  class Natural
    include Parsable
    def initialize(**args)
      @parser = lambda do |input|
        Tokenize.new(Nat.new, **args)
      end
    end
  end

  class Symbol
    include Parsable

    def initialize(literal)
      @parser = proc { Literal.new(literal) }
    end
  end

  class AbstractParser
    include Parsable

#     def parse(input, &block)
#       tree = @parser.call.parse(input)
#       if block_given?
#         yield tree
#       else
#         tree
#       end
#     end
    def parse(input, &block)
      tree = @parser.call.parse(input)
      if block_given?
        @tree = yield tree
      else
        @tree = tree
      end
    end
  end
end # of Yaparc
