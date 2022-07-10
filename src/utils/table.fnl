(fn assign! [tgt src]
  (collect [ k v (pairs src) :into tgt]  
    (values k v)) 
  tgt) 

{ : assign!}
