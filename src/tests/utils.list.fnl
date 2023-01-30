(import-macros { : mk-test } :test)
(local test (require :u-test))
(local list (require :utils.list))

(mk-test
  :is-list
  (let [
        b [1]
        c []]
    (test.equal (list.is-list b ) true)
    (test.equal (list.is-list c ) true)))

(mk-test
  :map
  (let [a []
        b [1 2 3]
        m1 (list.map a #$)
        m2 (list.map b #(+ 1 $1))]
    (test.equal (length m1) 0)
    (test.equal (table.concat m2) (table.concat [2 3 4]))))

(mk-test
  :some
  (let [a []
        b [1 2]
        r1 (list.some a #true)
        r2 (list.some b #(= $1 1))
        r3 (list.some b #(= $1 2))
        r4 (list.some b #(= $1 3))]
    (test.equal r1 false)
    (test.equal r2 true)
    (test.equal r3 true)
    (test.equal r4 false)))
(mk-test
  :find
  (let [a []
        b [1 2 3]]    
    (test.equal (list.find a #$) nil)
    (test.equal (list.find b #(= $1 1)) 1)
    (test.equal (list.find b #(= $1 2)) 2)
    (test.equal (list.find b #(= $1 3)) 3)))
(mk-test
  :range
  (test.equal
    (table.concat (list.range 1 10 1))
    (table.concat [1 2 3 4 5 6 7 8 9]))
  (test.equal
    (table.concat (list.range 1 10 2))
    (table.concat [1 3 5 7 9]))
  (test.equal
    (table.concat (list.range 1 10 20))
    (table.concat [])))

(mk-test
  :zip
  (fn concat [a b]
    (table.concat
      (list.map a table.concat)
      (list.map b table.concat)))
  (test.equal
    (concat (list.zip [1 2 3] [:a :b]))
    (concat [[1 :a] [2 :b]]))
  (test.equal
    (concat (list.zip [:a :b] [1 2 3]))
    (concat [[:a 1] [ :b 2]])))

(mk-test
  :concat
  (test.equal
    (table.concat
      (list.concat [] [1 2]))
    (table.concat
      [1 2]))
  (test.equal
    (table.concat
      (list.concat [1 2] []))
    (table.concat
      [1 2]))
  (test.equal
    (table.concat
      (list.concat [1 2] [3 4]))
    (table.concat
      [1 2 3 4])))

(mk-test
  :filter
  (test.equal
    (table.concat
      (list.filter [1 2 3 4 5] #(< 2 $1)))
    (table.concat [3 4 5])))
(mk-test
  :partition
  (let [[a b] (list.partition [1 2 3 4] #(< $1 3))]
    (test.equal 
      (table.concat a)
      (table.concat [1 2]))
    (test.equal 
      (table.concat b)
      (table.concat [3 4]))))
