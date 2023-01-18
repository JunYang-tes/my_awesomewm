(fn assign [tgt src]
  (list (sym :do)
    (icollect [i k (ipairs src)] 
        (if (not= (% i 2) 0) 
          (do 
            (local v (. src (+ i 1))) 
            (list (sym :tset) tgt k v)))) 
    tgt)) 

(fn <- [tgt value]
  (assert (sym? tgt) "Expect symbol")
  (let [
        path-str (. tgt 1)
        path (icollect [i (: path-str :gmatch "([^.]+)")] i)]
        
     (if (= (length path) 1)
      `(set ,tgt ,value)
      (let [[tgt & path] path
            code (list (sym :tset) (sym  tgt))]
          (each [_ p (ipairs path)]
            (table.insert code p))
          (table.insert code value)
          (print code)
          code))))
  
{ : assign
  : <- }
