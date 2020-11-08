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
end
