require 'pry-byebug'
require 'minitest/autorun'
require_relative 'parser'

class ParserTest <  MiniTest::Test
  def gen_parser(input)
    Parser.new(Tokenizer.new(input))
  end

  def test_num_parser
    parser = gen_parser("123")

    ret = parser.parse
    assert_equal Num, ret.class
    assert_equal 123, ret.value
    assert_equal "(Num 123)", ret.inspect
  end

  def test_str_parser
    parser = gen_parser('"this is string value"')

    ret = parser.parse
    assert_equal Str, ret.class
    assert_equal "this is string value", ret.value
    assert_equal "(Str \"this is string value\")", ret.inspect
  end

  def test_ident_parser
    parser = gen_parser('*ident*')

    ret = parser.parse
    assert_equal Ident, ret.class
    assert_equal "*ident*", ret.value
    assert_equal "(Ident *ident*)", ret.inspect
  end

  def test_ident_parser
    parser = gen_parser('(1 "hoge" foo)')

    ret = parser.parse
    assert_equal List, ret.class
    assert_equal [1, "hoge", "foo"], ret.value.map(&:value)
    assert_equal "(List (Num 1) (Str \"hoge\") (Ident foo))", ret.inspect
  end
end
