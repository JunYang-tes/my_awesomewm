(import-macros { : mk-test } :test)
(local test (require :u-test))
(tset test
      :hello-world
      (fn []
        (test.equal 2 2)))
(mk-test 
  :test-case
  (test.equal 2 2))
