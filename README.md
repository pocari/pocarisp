# pocarisp

lisp implemented by Ruby

## repl

```sh
% ruby pocarisp.rb
> (setq x 1)
1
> (defun hoge (y) (+ y y))
(lambda ((Ident y)) (Ident progn) (Cons (Ident +) (Ident y) (Ident y)))
> (hoge x)
2
```

## read script from file

```lisp
% cat sample.lsp
(defun fact (n)
  (if (= n 1)
    1
    (* n (fact (- n 1)))))
(princ (fact 10))
% cat sample.lsp | ruby pocarisp.rb
3628800
```
