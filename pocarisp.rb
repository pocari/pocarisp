require 'pry-byebug'
require 'strscan'
require_relative 'tokenizer'
require_relative 'parser'

def read_all(f = $stdin)
  f.read
end

module LispConstants
  def lnil
    Nil.instance
  end

  def lnil?(c)
    c == lnil
  end

  def ltrue?(c)
    !lnil?(c)
  end

  def ltrue
    True.instance
  end

end

class Scope
  def initialize(parent = nil)
    @variables = {}
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
  
  def inspect
    @variables.inspect
  end
end

class Evaluator
  include LispConstants
  def initialize()
    @scope = Scope.new
    setup_builtin
  end

  def setup_builtin
    @scope.add("atom", -> (expr) {
      Atom === expr ? ltrue : lnil
    })

    @scope.add("eq", -> (args) {
      eval(args.car) == eval(args.cdr.car) ? ltrue : lnil
    })

    @scope.add("car", -> (cons) {
      eval(cons).car
    })

    @scope.add("cdr", -> (cons) {
      eval(cons).cdr
    })

    @scope.add("cons", -> (car, cdr) {
      Cons.new(eval(car), eval(cdr))
    })

    @scope.add("+", -> (list) {
      # p [:+, list]
      result = 0
      c = list
      while !lnil?(c)
        result += eval(c.car).value
        c = c.cdr
      end
      Num.new(result)
    })

    @scope.add("-", -> (list) {
      raise 'too few arguments given to -' if lnil?(list)
      result = eval(list.car).value
      if lnil?(list.cdr)
        return Num.new(-result)
      end

      c = list.cdr
      while !lnil?(c)
        result -= eval(c.car).value
        c = c.cdr
      end
      Num.new(result)
    })

    @scope.add("*", -> (list) {
      result = 1
      c = list
      while !lnil?(c)
        result *= eval(c.car).value
        c = c.cdr
      end
      Num.new(result)
    })

    @scope.add("quote", -> (list) {
      list.car
    })

    @scope.add("lambda", -> (list) {
      Lambda.new(list.car, list.cdr.car)
    })

    @scope.add("funcall", -> (list) {
      # p [:car, list.car]
      apply_func(Cons.new(eval(list.car), list.cdr))
    })
  end

  def eval(expr)
    case expr
    when Ident
      # p [:find_var, expr.value, @scope]
      @scope.find(expr.value)
    when Atom
      expr
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
    apply_func(list)
  end

  def lambda_call(f, args)
    # p [:f_form, f.form]
    # p [:f_args, f.args]
    # p [:args, args]
    cur_scope = @scope
    @scope = @scope.sub_scope
    i = 0
    arg_list = []
    c = f.args
    a = args
    while !lnil?(c)
      arg_list << [c.car.value, eval(a.car)]
      i += 1
      c = c.cdr
      a = a.cdr
    end
    # p [:arg_list, arg_list]
    cur_scope = @scope
    arg_list.each do |var, val|
      # p [:add_scope, var, val]
      @scope.add(var, val)
    end
    eval(f.form)
  ensure
    @scope = cur_scope
  end

  def apply_func(list)
    # p [:apply_func, list.car]
    if Lambda === list.car
      lambda_call(list.car, list.cdr)
    else
      ident_name = list.car.value
      func = @scope.find(ident_name)
      if func
        func.call(list.cdr)
      else
        raise "#{ident_name} not found"
      end
    end
  end
end

class Printer
  include LispConstants

  def print(expr)
    puts my_inspect(expr)
  end

  def my_inspect(expr)
    case expr
    when Atom
      expr.value_inspect
    when Cons
      c = expr
      ret = []
      while c != lnil
        ret << my_inspect(c.car)
        c = c.cdr
      end
      "(#{ret.join(' ')})"
    when Lambda
      expr.value_inspect
    end
  end
end

require 'stringio'
def main
  e = Evaluator.new
  printer = Printer.new
  loop do
    print "> "
    line = gets
    break unless line
    parser = Parser.new(Tokenizer.new(read_all(StringIO.new(line))))
    s_expr = parser.parse
    printer.print(e.eval(s_expr))
  end
end

if __FILE__ == $0
  main
end
