(fn make-list [...]
  (local r [...]) 
  (setmetatable r {
                   :__is_list true}))
                    

(fn is-list? [a]
  a.__is_list) 

(fn some [list predict?]
  (var found false)
  (each [_ item (ipairs list)] :util found 
    (if (predict? item) 
      (set found true))) 
  found) 

(fn map [list f]
  (icollect [i v (ipairs list)] 
    (f v i))) 

(fn find-index [list entry] 
  (-> list 
    (map (fn [v i] [i v])) 
    (filter (fn [[i v]] (= v entry))) 
    (. 1))) 

(fn range [from to step]
  (local list [])
  (var start from)
  (while (< start to) 
    (table.insert list start) 
    (set start (+ start (or step 1)))) 
  (make-list list)) 
    
(fn zip [ a b]
  (let [ [ x y] (if (< (length a) (length b))  
                    [a b] 
                    [b a])]
    (icollect [i v (ipairs x)] 
      [(. a i) (. b  i)])))
                    
(fn concat [a b] 
  (local r [(table.unpack a)]) 
  (each [_ v (ipairs b)] 
    (table.insert r v)) 
  r) 

(fn filter [list should-remain?]
  (icollect [_ v (ipairs list)] 
    (if (should-remain? v) 
        v))) 


{ 
  : make-list
  : filter
  : map
  : some
  : range 
  : concat
  : find-index 
  : zip} 
