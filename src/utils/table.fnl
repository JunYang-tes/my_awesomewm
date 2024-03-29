(fn assign! [tgt src]
  (collect [ k v (pairs (or src {})) :into tgt]  
    (values k v)) 
  tgt) 
(fn assign [tgt src] 
  (local r {}) 
  (assign! r tgt) 
  (assign! r src) 
  r) 
(fn hybrid [list table]
  (let [r {}]
    (each [i v (ipairs list)]
      (tset r i v))
    (assign! r table)))
(fn weak-table [mode]
  (let [tbl {}]
    (setmetatable tbl {:__mode mode})
    tbl))
(fn weak-key-table []
  (weak-table :k))
(fn weak-value-table []
  (weak-table :v))
(fn partition [tbl predicate?]
  (let [a {}
        b {}]
    (each [k v (pairs tbl)]
      (if (predicate? k v)
        (tset a k v)
        (tset b k v)))
    [a b]))
(fn keys [tbl]
  (icollect [_ v (pairs tbl)]
    v))

{ : assign!
  : assign 
  : hybrid
  : partition
  : keys
  : weak-table
  : weak-key-table
  : weak-value-table}
