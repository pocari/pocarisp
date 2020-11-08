Token = Struct.new(:type, :value, :pos)
class Tokenizer
  class TokenizeError < StandardError
    def initialize(input, pos, msg)
      @input = input
      @pos = pos
      @msg = msg
    end

    def message
      lines = @input.lines
      count = @pos
      target_line_index = lines.find_index {|line| count -= line.size; count <= 0}

      # 最後の行に改行がない場合でもエラメッセージ用につける
      lines[-1] = lines[-1].chomp + "\n"
      # 最後の5行ぐらいをエラーメッセージに使う
      error_lines = lines.each.with_index(1).map { |line, no| [no, line] }[0 .. target_line_index].last(5)
      # 最後の行の中でのカラムの位置を計算
      error_column = @pos
      if target_line_index > 0
        # 前の行までの文字数全体をposから引くと、最後の行でのカラム位置になる
        error_column -= lines[0 ..target_line_index - 1].map(&:size).sum
      end
      max_line_no, _ = error_lines.max_by {|no, line| no}
      error_lines << [nil, (" " * (error_column - 1)) + "^\n"]
      error_lines << [nil, (" " * (error_column - 1)) + @msg.to_s + "\n"]
      line_no_size = max_line_no.to_s.size
      error_lines.map { |no, line|
        if no
          sprintf("%*d: %s", line_no_size + 1, no, line)
        else
          sprintf("%s%s", (' ' * (line_no_size + 1 + 3)), line)
        end
      }.join
    end
  end

  def initialize(input)
    @input = input
    @s = StringScanner.new(input)
  end

  def next
    tokenize
  end

  # /+ - * / @ $ % ^ & _ = < > ~ .
  IDENT_PREFIX_REGEXP = Regexp.compile('[a-zA-Z+\\-*/@$%^&_=<>~.]')
  # 上記に加えて、数値も含めた文字の1文字以上の繰り返し
  IDENT_REGEXP = Regexp.compile('[a-zA-Z+\\-*/@$%^&_=<>~.0-9]+')
  def tokenize
    @s.skip(/\s*/)
    @current_token_pos = @s.pos
    case
    when @s.match?(/\d/)
      new_token(:tk_num, tokenize_num)
    when @s.match?(/"/)
      new_token(:tk_str, tokenize_str)
    when @s.scan(/\(/)
      new_token(:tk_lparen)
    when @s.scan(/\)/)
      new_token(:tk_rparen)
    when @s.match?(IDENT_PREFIX_REGEXP)
      new_token(:tk_ident, tokenize_ident)
    when @s.empty?
      new_token(:tk_eof)
    else
      raise "unknown token"
    end
  end

  def tokenize_ident
    @s.scan(IDENT_REGEXP)
  end

  def tokenize_num
    tk = @s.scan(/\d+/)
    tk.to_i
  end

  def tokenize_str
    tk = @s.scan(/"/)
    buf = []
    loop do
      ch = @s.getch
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
      when nil
        raise tokenize_error('unterminated string literal')
      else
        buf << ch
      end
    end
  end

  def tokenize_error(msg)
    TokenizeError.new(
      @input,
      @s.pos,
      msg
    )
  end

  def new_token(type, val = nil)
    Token.new(type, val, @current_token_pos)
  end
end

