require 'pry-byebug'
require 'minitest/autorun'
require_relative 'parser'

class ParserTest <  MiniTest::Test
  def gen_parser(input)
    Parser.new(Tokenizer.new(input))
  end

  def test_num_parser
    parser = gen_parser("123")

    ret = parser.parse.first
    assert_equal Num, ret.class
    assert_equal 123, ret.value
    assert_equal "(Num 123)", ret.inspect
  end

  def test_str_parser
    parser = gen_parser('"this is string value"')

    ret = parser.parse.first
    assert_equal Str, ret.class
    assert_equal "this is string value", ret.value
    assert_equal "(Str \"this is string value\")", ret.inspect
  end

  def test_ident_parser
    parser = gen_parser('*ident*')

    ret = parser.parse.first
    assert_equal Ident, ret.class
    assert_equal "*ident*", ret.value
    assert_equal "(Ident *ident*)", ret.inspect
  end

  def test_cons_parser
    parser = gen_parser('(1 "hoge" foo)')

    ret = parser.parse.first
    assert_equal Cons, ret.class
    assert_equal [1, "hoge", "foo"], ret.value
    assert_equal "(Cons (Num 1) (Str \"hoge\") (Ident foo))", ret.inspect
  end

  def test_nested_cons_parser
    parser = gen_parser('(1 (2 (3 4) 5) 6))')

    assert_raises Parser::ParseError do
      parser.parse
    end
  end

  def test_empty_cons
    parser = gen_parser('()')

    ret = parser.parse.first
    assert_equal Nil, ret.class
    assert_nil ret.value
    assert_equal "Nil", ret.inspect
  end

  def test_multiple_expr
    parser = gen_parser(<<~EOS)
    (+ 1 2 3)
    (+ 4 5 6)
    EOS

    ret =  parser.parse.shift
    assert_equal "(Cons (Ident +) (Num 1) (Num 2) (Num 3))", ret.shift.inspect
    assert_equal "(Cons (Ident +) (Num 4) (Num 5) (Num 6))", ret.shift.inspect
    assert_nil ret.shift

  end
end
