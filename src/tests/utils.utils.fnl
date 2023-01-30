(import-macros { : mk-test } :test)
(local inspect (require :inspect))
(local test (require :u-test))
(local utils (require :utils.utils))

(mk-test 
  :memoed

  (var called 0)
  (let [a (utils.memoed (fn [a] 
                          (set called (+ called 1))
                          1))
        b {}]
    (a 0)
    (test.equal called 1)
    (a 0)
    (test.equal called 1)
    (a {})
    (test.equal called 2)
    (a {})
    (test.equal called 3)))
