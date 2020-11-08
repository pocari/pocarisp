require 'pry-byebug'
require 'minitest/autorun'
require_relative 'tokenizer'

class TokenizerTest <  MiniTest::Test
  def test_read_number
    tk = Tokenizer.new("123")

    token = tk.next
    assert_equal :tk_num, token.type
    assert_equal 123, token.value
  end

  def test_read_str
    tk = Tokenizer.new('"this is a string"')

    token = tk.next
    assert_equal :tk_str, token.type
    assert_equal "this is a string" , token.value
  end

  def test_read_str_with_escaped
    tk = Tokenizer.new('"this is \ta \n string"')

    token = tk.next
    assert_equal :tk_str, token.type
    assert_equal "this is \ta \n string" , token.value
  end

  def test_read_lparen
    tk = Tokenizer.new('(')

    token = tk.next
    assert_equal :tk_lparen, token.type
    assert_nil token.value
  end

  def test_read_rparen
    tk = Tokenizer.new(')')

    token = tk.next
    assert_equal :tk_rparen, token.type
    assert_nil token.value
  end

  def test_ignore_white_space
    tk = Tokenizer.new('   12 \t\n  ')

    token = tk.next
    assert_equal :tk_num, token.type
    assert_equal 12, token.value
  end

  def test_error_unterminated_string
    tk = Tokenizer.new(<<~'EOS'.chomp)
    123
    "hoge"
    "foooo
    EOS

    token = tk.next
    assert_equal :tk_num, token.type
    assert_equal 123, token.value

    token = tk.next
    assert_equal :tk_str, token.type
    assert_equal "hoge", token.value

    e = assert_raises Tokenizer::TokenizeError do
      p tk.next
    end

    assert_equal <<EOS.chomp, e.message.chomp
 1: 123
 2: "hoge"
 3: "foooo
          ^
          unterminated string literal
EOS
  end

  def test_tokenize_variable1
    tk = Tokenizer.new('hoge')

    token = tk.next
    assert_equal :tk_ident, token.type
    assert_equal "hoge", token.value
  end

  def test_tokenize_variable2
    tk = Tokenizer.new('a0')

    token = tk.next
    assert_equal :tk_ident, token.type
    assert_equal "a0", token.value
  end

  def test_tokenize_variable3
    tk = Tokenizer.new('*var*')

    token = tk.next
    assert_equal :tk_ident, token.type
    assert_equal "*var*", token.value
  end

  def test_eof
    tk = Tokenizer.new('123')

    token = tk.next
    assert_equal :tk_num, token.type
    assert_equal 123, token.value

    token = tk.next
    assert_equal :tk_eof, token.type
    assert_nil token.value
  end
end
