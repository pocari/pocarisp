require 'pry-byebug'
require 'minitest/autorun'
require_relative 'pocarisp'

class RispTest <  MiniTest::Test
  def test_read_number
    tk = Tokenizer.new("123")
    assert_equal [:tk_num, 123], tk.next
  end

  def test_read_str
    tk = Tokenizer.new('"this is a string"')
    assert_equal [:tk_str, "this is a string"], tk.next
  end

  def test_read_str_with_escaped
    tk = Tokenizer.new('"this is \ta \n string"')
    assert_equal [:tk_str, "this is \ta \n string"], tk.next
  end

  def test_read_lparen
    tk = Tokenizer.new('(')
    assert_equal [:tk_lparen, nil], tk.next
  end

  def test_read_rparen
    tk = Tokenizer.new(')')
    assert_equal [:tk_rparen, nil], tk.next
  end

  def test_ignore_white_space
    tk = Tokenizer.new('   12 \t\n  ')
    assert_equal [:tk_num, 12], tk.next
  end

  def test_error_unterminated_string
    tk = Tokenizer.new(<<~'EOS'.chomp)
    123
    "hoge"
    "foooo
    EOS

    assert_equal [:tk_num, 123], tk.next
    assert_equal [:tk_str, "hoge"], tk.next
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
end
