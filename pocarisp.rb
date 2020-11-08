require 'strscan'

def read_all(f = $stdin)
  f.read
end

class Tokenizer
  def initialize(input)
    @s = StringScanner.new(input)
  end

  def next
    tokenize
  end

  def tokenize
    case
    when @s.match?(/^\d/)
      [:tk_num, tokenize_num]
    when @s.match?(/\A"/)
      [:tk_str, tokenize_str]
    else
      raise "unknown token"
    end
  end

  def tokenize_num
    tk = @s.scan(/\d+/)
    tk.to_i
  end

  def tokenize_str
    tk = @s.scan(/"/)
    buf = []
    while ch = @s.getch
      case ch
      when '"'
        return buf.join
      when '\\'
        case c2 = @s.getch
        when 'n'
          buf << "\n"
        when 't'
          buf << "\t"
        when 'b'
          buf << "\b"
        else
          buf << c2
        end
      else
        buf << ch
      end
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
