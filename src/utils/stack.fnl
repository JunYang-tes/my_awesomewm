(fn make-stack []
  (let [list []]
    {:push (fn [val]
             (table.insert list val))
     :pop (fn [] (table.remove list))
     :empty? (fn [] (= (length list) 0))}))

{ : make-stack}
