require 'pry-byebug'
require 'strscan'
require_relative 'tokenizer'
require_relative 'parser'

def read_all(f = $stdin)
  f.read
end

class Scope
  def initialize(parent = nil)
    @variables = {}
    @lambdas = {}
    @parent = parent
  end

  def find(ident)
    v = @variables[ident]
    v ? v : @parent&.find(ident)
  end

  def add(ident, value)
    @variables[ident] = value
  end

  def sub_scope
    Scope.new(self)
  end
end

class Evaluator
  def initialize()
    @scope = Scope.new
    setup_builtin
  end

  def setup_builtin
    @scope.add("atom", -> (expr) {
      Atom === expr
    })
    @scope.add("eq", -> (e1, e2) {
      e1 == e2
    })
    @scope.add("car", -> (cons) {
      cons.car
    })
    @scope.add("cdr", -> (cons) {
      cons.cdr
    })
    @scope.add("cons", -> (car, cdr) {
      Cons.new(car, cdr)
    })
    @scope.add("+", -> (list) {
      sum = 0
      c = list
      while c != Nil.instance
        sum += eval(c.car)
        c = c.cdr
      end
      sum
    })
  end

  def eval(expr)
    case expr
    when Atom
      expr.value
    when Cons
      eval_list(expr)
    end
  end

  def eval_list(list)
    f = list.car
    if Ident === f
      apply_func_or_special(list)
    else
      raise "#{f} is not a function"
    end
  end

  def apply_func_or_special(list)
    f = list.car
    if special?(f)
      apply_special(list)
    else
      apply_func(list)
    end
  end

  def special?(ident)
    false
  end

  def apply_func(list)
    ident_name = list.car.value
    func = @scope.find(ident_name)
    unless func
      raise "#{ident_name} not found"
    end
    func.call(list.cdr)
  end
end

require 'stringio'
def main
  e = Evaluator.new
  loop do
    print "> "
    line = gets
    break unless line
    parser = Parser.new(Tokenizer.new(read_all(StringIO.new(line))))
    s_expr = parser.parse
    p e.eval(s_expr)
  end
end

if __FILE__ == $0
  main
end
