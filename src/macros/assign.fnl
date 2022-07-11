(fn assign [tgt src]
  (list (sym :do)
    (icollect [i k (ipairs src)] 
        (if (not= (% i 2) 0) 
          (do 
            (local v (. src (+ i 1))) 
            (list (sym :tset) tgt k v)))) 
    tgt)) 
  
{ : assign}
