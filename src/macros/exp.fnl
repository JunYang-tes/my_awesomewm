(fn infix [...]
  (local fennel (require :fennel))
  (local priority 
    {:+ 1
     :- 1
     :* 2
     :/ 2})
  (fn is-operator [txt]
    (or 
      (= txt :+)
      (= txt :-)
      (= txt :*)
      (= txt :/)
      (= txt "..")))
  (fn exp-type [exp]
    (if (sym? exp) :sym 
        (list? exp) :list
        (table? exp) :table
        (sequence? exp) :sequence
        (= (type exp) :number) :number
        (= (type exp) :string) :string
        :unknown))
  (fn is-s-exp [exp]
    (and (= (exp-type exp) :list)
         (= (exp-type (. exp 1)) :sym)
         (is-operator (. exp 1 1))))
  (var fns nil)
  (set fns
    {:basic 
      (fn basic [exp]
        (match (exp-type exp)
          :number exp
          :string exp
          :sym exp
          :list (do
                  (if (or (= (length exp) 1)
                          (= (length exp) 2)
                          (is-s-exp exp))
                    exp
                    (and (> (length exp) 2)
                         (= (exp-type (. exp 2)) :sym)
                         (is-operator (. exp 2 1))) (fns.infix (unpack exp))
                    ;; s call , args need to be handled
                    (let [[f & args] exp]
                      (list f
                            (unpack
                              (icollect [_ v (ipairs args)]
                                (fns.infix v)))))))))
      :infix (fn [...]
              (let [params [...]]
                (if (= (length params) 1)
                  (fns.basic (. params 1))
                  (= (length params) 3) (let [[a b c] params]
                                          (list 
                                            b
                                            (fns.basic a)
                                            (fns.basic c)))
                  (let [[a op1 b op2 & c] params
                        op1-priority (. priority (. op1 1))
                        op2-priority (. priority (. op2 1))]
                    (if (>= op1-priority op2-priority)
                      (fns.infix 
                        (list op1 (fns.basic a)
                                  (fns.basic b))
                        op2
                        (unpack c))
                      (list
                        op1
                        (fns.basic a)
                        (fns.infix b op2 (unpack c))))))))
                        ; (list 
                        ;   op2
                        ;   (fns.basic b)
                        ;   (fns.infix (unpack c)))))))))
     })
  (fns.infix ...))

{ : infix }
