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
  def initialize(parser)
    @parser = parser
    @scope = Scope.new
  end

  def eval(expr)
    case expr
    when Atom
      expr.value
    when List
      
    end
  end
end

def main
  binding.pry
  parser = Parser.new(Tokenizer.new(read_all))
  p parser.parse
end

if __FILE__ == $0
  main
end
