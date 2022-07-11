(fn assign! [tgt src]
  (collect [ k v (pairs (or src {})) :into tgt]  
    (values k v)) 
  tgt) 

{ : assign!}
