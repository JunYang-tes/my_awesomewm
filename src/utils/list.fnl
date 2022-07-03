(fn some [list predict?]
  (var found false)
  (each [_ item (ipairs list)] :util found 
    (if (predict? item) 
      (set found true))) 
  found) 

(fn range [from to step]
  (local list [])
  (var start from)
  (while (< start to) 
    (table.insert list start) 
    (set start (+ start (or step 1)))) 
  list) 
    
(fn zip [ a b]
  (let [ [ x y] (if (< (length a) (length b))  
                    [a b] 
                    [b a])]
    (icollect [i v (ipairs x)] 
      [(. a i) (. b  i)])))
                    
(fn p [...]
    (local f (require :fennel)) 
    (print (f.view ...))) 

{ : some
  : range 
  : zip} 
