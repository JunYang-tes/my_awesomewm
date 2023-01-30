(import-macros { : mk-test } :test)
(local inspect (require :inspect))
(local test (require :u-test))
(local r (require :lite-reactive.observable))
(mk-test
  :observable.get/set
  (let [value (r.value 0)]
    (test.equal (value ) 0)
    (value 1)
    (test.equal (value ) 1)))
(mk-test
  :observable.add-observer
  (var fired 0)
  (let [value (r.value 0)
        remove (value.add-observer #(set fired $1))]
    (value 1)
    (test.equal fired 1)
    (remove)
    (value 2)
    (test.equal fired 1)
    (test.equal (value 2))))
(mk-test
  :observable.observe-deep
  (var fired 0)
  (let [a (r.value 0)
        b (r.value a)
        c (r.value b)]
    (r.observe-deep c (fn [] (set fired (+ fired 0))))
    (a 1)
    (test.equal fired 1)
    (b (r.value 0))
    (test.equal fired 2)
    (b 1)
    (test.equal fired 3)))
  

(mk-test
  :observable.map              
  (let [a (r.value 0)
        b (r.map a #(* 2 $1))]
    (test.equal (b 0))
    (a 1)
    (test.equal (b 2))))

(mk-test 
  :observable.mapn
  (let [a (r.value 0)
        b (r.value 1)
        c (r.mapn [a b] #(+ (. $1 1) (. $1 2)))]
    (test.equal (c ) 1)
    (a 1)
    (test.equal (c ) 2)
    (b 2)
    (test.equal (c ) 3)))
  

(mk-test
  :observable.flat
  (let [a (r.value 0)
        b (r.value a)
        c (r.flat b)]
    
    (test.equal (c) 0)
    (a 1)
    (test.equal (c) 1)
    ;; change content of b to a new observable
    (let [a1 (r.value 0)]
      (b a1)
      (test.equal (c) 0)
      (a1 1)
      (test.equal (c) 1)
      (a 2)
      (test.equal (c) 1))
    ;; change content of b to non-observable
    (b 3)
    (test.equal (c) 3)))

(mk-test
  :observable.flat-deep
  (let [a (r.value 0)
        b (r.value a)
        c (r.value b)
        d (r.value c)
        e (r.flat-deep d)]
    (test.equal (e) 0)
    (a 1)
    (test.equal (e) 1)
    ;; make it deeper
    (let [a0 (r.value 0)]
      (a a0)
      (test.equal (e) 0))
    ;; make it shallower
    (b 10)
    (test.equal (e) 10)
    ;; restore
    (b a)
    (a 20)
    (test.equal (e) (a))
    (c 0)
    (test.equal (e) (c))
    (d a)
    (a 10)
    (test.equal (e) (a))))
(mk-test
  :observable.flat-deep.change-chain
  (let [a (r.value 0)
        b (r.value a)
        c (r.value b)
        d (r.value c)
        e (r.flat-deep d)]
    (test.equal (e) 0)
    (let [a (r.value 0)
          b (r.value a)]
      (c b)
      (test.equal (e) 0)
      (a :hello)
      (test.equal (e) :hello))))

(mk-test
  :observable.get
  (let [a (r.value 0)
        b (r.value a)
        c (r.value b)]
    (test.equal (r.get c) 0)
    (a 10)
    (test.equal (r.get c) 10)))

(mk-test
  :observable.flat-map
  (let [a (r.value 0)
        b (r.flat-map a #(r.value $1))]
    (test.equal (b ) 0)))

(mk-test
  :observable.flat-collect
  (let [a (r.value [0 1 [2 3]])
        b (r.value [a  a 4 5])
        c (r.value b)]
    (test.equal (inspect (r.flat-collect [0 1 2]))
                (inspect [0 1 2]))
    (test.equal (inspect (r.flat-collect c))
                (inspect [0 1 2 3 0 1 2 3 4 5]))))
(mk-test
  :observable.observe-list-deep
  (var fired 0)
  (let [a (r.value [0 1])
        b (r.value 1)
        c (r.value [a,b])
        d (r.value [a c])]
    (r.observe-list-deep d (fn [] (set fired (+ fired 1))))
    (a [1 1])
    (test.equal fired 1)
    (b 1)
    (test.equal fired 2)
    (let [a (r.value :hello)
          b (r.value [a])]
      (c b)
      (test.equal fired 3)
      (a 1)
      (test.equal fired 4))))
(mk-test
  :observable.observe-list-deep.1
  (var fired 0)
  (let [a (r.value [1 1])
        b [a]]
    (r.observe-list-deep b (fn [] (set fired (+ fired 1))))
    (a [1 2])
    (test.equal fired 1)))
    
