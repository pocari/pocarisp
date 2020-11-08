require 'strscan'
require_relative 'tokenizer'
require_relative 'parser'

def read_all(f = $stdin)
  f.read
end

def main
  parser = Parser.new(Tokenizer.new(read_all))
  p parser.parse
end

if __FILE__ == $0
  main
end
