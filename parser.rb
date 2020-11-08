require 'singleton'
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

class Nil < Atom
  include Singleton

  def initialize
    super(nil, nil)
  end

  def value_inspect
    "nil"
  end

  def inspect
    "Nil"
  end
end

class Ident < Atom
end

class Cons < Node
  attr_reader :car, :cdr, :special
  def initialize(token, car, cdr)
    super(token, nil)
    @car = car
    @cdr = cdr
    @special = false
  end

  def value_inspect
    return Nil.instance if self == Nil.instance

    ret = []
    my_each_cons do |car|
      ret << car.inspect
    end

    ret.join(" ")
  end

  def value
    return Nil.instance if self == Nil.instance
    ret = []
    my_each_cons do |car|
      ret << car.value
    end

    ret
  end

  def my_each_cons
    ret = []
    c = self
    while c != Nil.instance
      yield c.car
      c = c.cdr
    end
  end

  def reverse
    cur = Nil.instance
    n = self
    while n != Nil.instance
      cur = Cons.new(n.car.token, n.car, cur)
      n = n.cdr
    end
    cur
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
  #              | nil
  # list         := "(" s_expr* ")"
  # atomi_symbol := number
  #              |  string
  #              |  ident
  def parse
    s_expr
  end

  def s_expr
    atom = parse_atomic_symbol
    return atom if atom
    parse_list
  end

  def parse_list
    tk = expect(:tk_lparen)
    return Nil.instance if match(:tk_rparen)
    cons =  Nil.instance
    loop do
      e = s_expr
      cons = Cons.new(e.token, e, cons)
      return cons.reverse if match(:tk_rparen)
      raise ParseError, 'unexpected EOF' if match(:tk_eof)
    end
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

  def reset_token(tk)
    @t.reset_token(tk.pos)
  end

  def expect(tk_type)
    unless peek(tk_type)
      raise ParseError, "unexpected token: #{@token}"
    end
    @token.tap { next_token }
  end

  def match(tk_type)
    unless peek(tk_type)
      return false
    end
    @token.tap { next_token }
    true
  end

  def peek(tk_type)
    @token.type == tk_type
  end
end
