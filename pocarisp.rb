require 'strscan'
require_relative 'tokenizer'

def read_all(f = $stdin)
  f.read
end

def main
  tk = Tokenizer.new(read_all)
  exit(tk.next.value)
end

if __FILE__ == $0
  main
end
