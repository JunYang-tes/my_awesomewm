(math.randomseed (os.time))

(fn random [from to]
  (local r (math.random)) 
  (math.floor (+ (* r (- to from)) from))) 
                                   
{ : random }
