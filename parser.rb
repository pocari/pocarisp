require_relative 'tokenizer'

class Node
  attr_reader :token, :value
  def initialize(token, val)
    @token = token
    @value = val
  end

  def inspect
    "(#{self.class.name} #{value_inspect})"
  end
end

class Atom < Node
  def value_inspect
    value
  end
end

class Num < Atom
end

class Str < Atom
  def value_inspect
    "\"#{value}\""
  end
end

class Ident < Atom
end

class List < Node
  attr_reader :special
  def initialize(token, val, special)
    super(token, val)
    @special = special
  end

  def value_inspect
    value.map {|e| e.inspect }.join(" ")
  end
end

class Parser
  class ParseError < StandardError; end;

  def initialize(tokenizer)
    @t = tokenizer
    @token = @t.next
  end

  # s_expr       := atomic_symbol
  #              | list
  # list         := "(" s_expr* ")"
  # atomi_symbol := number
  #              |  string
  #              |  ident
  def parse
    atom = parse_atomic_symbol
    return atom if atom
    parse_list
  end


  def parse_list
    tk = expect(:tk_lparen)
    list = List.new(tk, [], false)

    loop do
      list.value << parse
      if peek(:tk_rparen)
        break
      end

      if peek(:tk_eof)
        raise ParseError, "unexpected eof"
      end
    end

    list
  end

  def parse_atomic_symbol
    case @token.type
    when :tk_num
      Num.new(@token, @token.value).tap {
        next_token
      }
    when :tk_str
      Str.new(@token, @token.value).tap {
        next_token
      }
    when :tk_ident
      Ident.new(@token, @token.value).tap {
        next_token
      }
    else
      nil
    end
  end

  def next_token
    @token = @t.next
  end

  def expect(tk_type)
    unless peek(tk_type)
      raise ParseError, "unexpected token: #{@token}"
    end
    @token.tap { next_token }
  end

  def peek(tk_type)
    @token.type == tk_type
  end
end

