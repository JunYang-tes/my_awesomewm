(local {: filter} (require :utils.list))
(local callbacks {})

(fn connect-signal [name callback]
  (local cb (. callbacks name)) 
  (if cb 
      (do
        (table.insert cb callback)) 
      (do 
        (tset callbacks name [callback]))))
(fn disconnect-signal [name callback]
    (let [cb (or (. callbacks name) [])]
      (tset callbacks
            name
            (filter cb #(not= $1 callback))))) 

(fn emit [name ...]
  (each [_ cb (ipairs (or (. callbacks name) 
                          []))]
    (pcall cb ...))) 

{ : emit
  : disconnect-signal
  : connect-signal} 
