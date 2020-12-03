require 'pry-byebug'
require 'minitest/autorun'
require_relative 'pocarisp'

class ParserTest <  MiniTest::Test
  def gen_parser(input)
    Parser.new(Tokenizer.new(input))
  end

  def setup_evaluator
    e = Evaluator.new
    root_env = Env.new
    e.setup_builtin(root_env)
    @e, @root_env = e, root_env
  end

  def setup
    setup_evaluator
  end

  def eval_expr(line)
    parser = Parser.new(Tokenizer.new(read_all(StringIO.new(line))))
    ret = parser.parse
    result = nil
    ret.each do |s_expr|
      result = @e.eval(@root_env, s_expr)
    end
    result
  end

  def test_eval_number
    ret = eval_expr(<<~EOS)
    1
    EOS
    assert_equal Num, ret.class
    assert_equal 1, ret.value
  end

  def test_eval_str
    ret = eval_expr(<<~EOS)
    "hoge"
    EOS
    assert_equal Str, ret.class
    assert_equal "hoge", ret.value
  end

  def test_eval_plus
    ret = eval_expr(<<~EOS)
    (+ 1 2 3 4)
    EOS
    assert_equal Num, ret.class
    assert_equal 10, ret.value
  end

  def test_eval_minus_1
    ret = eval_expr(<<~EOS)
    (- 1)
    EOS
    assert_equal Num, ret.class
    assert_equal -1, ret.value
  end

  def test_eval_minus_2
    ret = eval_expr(<<~EOS)
    (- 10 1 2 3)
    EOS
    assert_equal Num, ret.class
    assert_equal 4, ret.value
  end

  def test_eval_multiple
    ret = eval_expr(<<~EOS)
    (* 2 3 4)
    EOS
    assert_equal Num, ret.class
    assert_equal 24, ret.value
  end

  def test_eval_progn
    ret = eval_expr(<<~EOS)
    (progn 2 3 4)
    EOS
    assert_equal Num, ret.class
    assert_equal 4, ret.value
  end

  def test_eval_setq
    ret = eval_expr(<<~EOS)
    (progn
      (setq a 2)
      (setq b 3)
      (setq c (+ 1 a b))
      (+ 1 c)
    )
    EOS
    assert_equal Num, ret.class
    assert_equal 7, ret.value
  end

  def test_eval_progn
    ret = eval_expr(<<~EOS)
    (progn
      (setq a 2)
      (setq b 3)
      (setq c (+ 1 a b))
      (+ 1 c)
    )
    EOS
    assert_equal Num, ret.class
    assert_equal 7, ret.value
  end

  def test_multiple_expr
    ret = eval_expr(<<~EOS)
      (setq a 2)
      (setq b 3)
      (setq c (+ 1 a b))
      (+ 1 c)
    EOS
    assert_equal Num, ret.class
    assert_equal 7, ret.value
  end

  def test_defun
    ret = eval_expr(<<~EOS)
    (defun hoge (a b c)
      (setq d (+ a b c))
      (* d 2))
    (hoge 1 2 3)
    EOS
    assert_equal Num, ret.class
    assert_equal 12, ret.value
  end
end
