require 'strscan'

def read_all
  $stdin.read
end

class Tokenizer
  def initialize(input)
    @scanner = StringScanner.new(input)
  end

  def next
    tokenize
  end

  def tokenize
    s = @scanner
    case
    when tk = s.scan(/\d+/)
      tk.to_i
    else
      raise "unknown token"
    end
  end
end

def main
  tk = Tokenizer.new(read_all)
  exit(tk.next)
end

if __FILE__ == $0
  main
end
