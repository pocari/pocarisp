require 'minitest/autorun'
require_relative 'pocarisp'

class RispTest <  MiniTest::Test
  def test_read_int
    tk = Tokenizer.new("123")
    assert_equal [:tk_str, 123], tk.next
  end
end
