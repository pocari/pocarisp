require 'minitest/autorun'
require_relative 'risp'

class RispTest <  MiniTest::Test
  def test_read_int
    tk = Tokenizer.new("123")
    assert_equal 123, tk.next
  end
end
