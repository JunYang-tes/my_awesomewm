(local awful (require :awful))
(local awesome-global (require :awesome-global))

(fn on-idle [f]
  (fn on-refresh [] 
    (pcall f) 
    (awesome-global.awesome.disconnect_signal :refresh on-refresh)) 
  (awesome-global.awesome.connect_signal :refresh on-refresh)) 
      
(fn focus [client] 
  (if client
    (set awesome-global.client.focus client))) 

{ : on-idle
  : focus} 
