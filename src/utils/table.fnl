(fn assign! [tgt src]
  (collect [ k v (pairs (or src {})) :into tgt]  
    (values k v)) 
  tgt) 
(fn assign [tgt src] 
  (local r {}) 
  (assign! r tgt) 
  (assign! r src) 
  r) 

{ : assign!
  : assign} 
