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

  def non_lnil?(c)
    ltrue?(c)
  end

  def ltrue
    True.instance
  end

end

class Env
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

  def inspect
    @variables.inspect
  end

  def sub_env
    self.class.new(self)
  end

  def keys
    @variables&.keys
  end
end

class Evaluator
  include LispConstants
  def setup_builtin(env)
    env.add("t", -> (e, expr) {
      ltrue
    })

    env.add("atom", -> (e, expr) {
      Atom === expr ? ltrue : lnil
    })

    env.add("eq", -> (e, args) {
      eval(e, args.car) == eval(e, args.cdr.car) ? ltrue : lnil
    })

    env.add("car", -> (e, cons) {
      eval(e, cons).car
    })

    env.add("cdr", -> (e, cons) {
      eval(e, cons).cdr
    })

    env.add("cons", -> (e, car, cdr) {
      Cons.new(eval(e, car), eval(e, cdr))
    })

    env.add("+", -> (e, list) {
      result = 0
      c = list
      while !lnil?(c)
        result += eval(e, c.car).value
        c = c.cdr
      end
      Num.new(result)
    })

    env.add("-", -> (e, list) {
      raise 'too few arguments given to -' if lnil?(list)
      result = eval(e, list.car).value
      if lnil?(list.cdr)
        return Num.new(-result)
      end

      c = list.cdr
      while !lnil?(c)
        result -= eval(e, c.car).value
        c = c.cdr
      end
      Num.new(result)
    })

    env.add("*", -> (e, list) {
      result = 1
      c = list
      while !lnil?(c)
        result *= eval(e, c.car).value
        c = c.cdr
      end
      Num.new(result)
    })

    env.add("quote", -> (e, list) {
      list.car
    })

    env.add("lambda", -> (e, list) {
      Lambda.new(e, list.car, list.cdr)
    })

    env.add("defun", -> (e, list) {
      name = list.car
      lambda_form = list.cdr
      sub_env = e.sub_env
      body = Cons.new(Ident.new('progn'), lambda_form.cdr)
      e.add(name.value, Lambda.new(sub_env, lambda_form.car, body))
    })

    env.add("funcall", -> (e, list) {
      eval_cons(e, list)
    })

    env.add("setq", -> (e, list) {
      ident = list.car
      value = list.cdr.car
      e.add(ident.value, eval(e, value))
    })

    env.add("progn", -> (e, list) {
      c = list
      ret = lnil
      while !lnil?(c)
        ret = eval(e, c.car)
        c = c.cdr
      end

      ret
    })

    env.add("if", -> (e, list) {
      raise 'too few arguments given to -' if lnil?(list)
      c = list

      condition = c.car
      c = c.cdr
      ccc = eval(e, condition)
      if not lnil?(ccc)
        raise 'too few arguments given to -' if lnil?(c)
        eval(e, c.car)
      else
        raise 'too few arguments given to -' if lnil?(c)
        c = c.cdr
        raise 'too few arguments given to -' if lnil?(c)
        eval(e, c.car)
      end
    })

    env.add("princ", -> (e, list) {
      c = list.car
      puts(c.value)
      c
    })
  end

  def eval(env, expr)
    case expr
    when Nil
      lnil
    when Ident
      env.find(expr.value)
    when Atom
      expr
    when Cons
      eval_cons(env, expr)
    end
  end

  def eval_cons(env, list)
    f = eval(env, list.car)
    case f
    when Lambda
      apply_lambda(env, f, list.cdr)
    when Proc
      f.call(env, list.cdr)
    else
      raise "#{f.inspect} is not a function"
    end
  end

  def apply_lambda(env, f, args)
    eargs = eval_list(env, args)
    fargs = f.args

    arg_list = []
    while non_lnil?(fargs) && non_lnil?(eargs)
      arg_list << [fargs.car, eargs.car]
      fargs = fargs.cdr
      eargs = eargs.cdr
    end

    lambda_env = f.env.sub_env
    arg_list.each do |k, v|
      lambda_env.add(k.value, v)
    end
    eval(lambda_env, f.form)
  end

  def eval_list(env, list)
    cur = list
    ret = lnil
    while non_lnil?(cur)
      ret = Cons.new(eval(env, cur.car), ret)
      cur = cur.cdr
    end
    lnil?(ret) ? lnil : ret.reverse
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
  root_env = Env.new
  e.setup_builtin(root_env)
  printer = Printer.new
  if  FileTest.pipe?($stdin)
    parser = Parser.new(Tokenizer.new(read_all(StringIO.new($stdin.read))))
    s_expr_list = parser.parse
    s_expr_list.each do |s_expr|
      e.eval(root_env, s_expr)
    end
  else
    loop do
      print "> "
      line = gets
      break unless line
      parser = Parser.new(Tokenizer.new(read_all(StringIO.new(line))))
      s_expr_list = parser.parse
      s_expr_list.each do |s_expr|
        printer.print(e.eval(root_env, s_expr))
      end
    end
  end
end

if __FILE__ == $0
  main
end
