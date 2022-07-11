(local callbacks {})

(fn connect-signal [name callback]
  (local cb (. callbacks name)) 
  (if cb 
      (do
        (table.insert cb callback)) 
      (do 
        (tset callbacks name [callback])))) 
        
(fn emit [name ...]
  (each [_ cb (ipairs (or (. callbacks name) 
                          []))]
    (pcall cb ...))) 
                
{ : emit
  : connect-signal} 
