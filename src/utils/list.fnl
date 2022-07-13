(fn some [list predict?]
  (var found false)
  (each [_ item (ipairs list)] :util found 
    (if (predict? item) 
      (set found true))) 
  found) 

(fn map [list f]
  (icollect [i v (ipairs list)] 
    (f v i))) 

(fn find [list predict?] 
  (var found nil) 
  (each [_ item (ipairs list)] :util found 
    (if (predict? item) 
        (set found item))) 
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
                    
(fn concat [a b] 
  (local r [(table.unpack a)]) 
  (each [_ v (ipairs b)] 
    (table.insert r v)) 
  r) 

(fn filter [list should-remain?]
  (icollect [_ v (ipairs list)] 
    (if (should-remain? v) 
        v))) 

(fn find-index [list entry] 
  (-> list 
    (map (fn [v i] [i v])) 
    (filter (fn [[i v]] (= v entry))) 
    (. 1))) 

(fn remove-value! [list value]
  (var ind   0) 
  (each [i v (ipairs list)] 
    (if (= v value) 
        (set ind i))) 
  (if (> ind 0) 
      (table.remove list ind)) 
  list) 

(fn reduce [list accumulator init]
  (var ret init) 
  (each [i v (ipairs list)] 
    (set ret (accumulator v ret))) 
  ret)
     
(fn max-by [list accessor]
  (reduce 
    list  
    (fn [item acc] 
      (local a (accessor item)) 
      (local b (accessor acc)) 
      (if (> a b) 
          item 
          acc))
    (. list 1))) 

{ 
  : filter
  : map
  : some
  : range 
  : concat
  : find-index 
  : find 
  : remove-value!
  : reduce
  : max-by       
  : zip} 
