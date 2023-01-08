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
(fn weak-key-table []
  (setmetatable {} {:__mode :k}))
(fn weak-value-table []
  (setmetatable {} {:__mode :v}))

{ : assign!
  : assign 
  : hybrid
  : weak-key-table
  : weak-value-table}
