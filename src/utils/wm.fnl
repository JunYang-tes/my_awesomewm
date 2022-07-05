(local {: awesome} (require :awesome-global))

(fn on-idle [f]
  (fn on-refresh [] 
    (pcall f) 
    (awesome.disconnect_signal :refresh on-refresh)) 
  (awesome.connect_signal :refresh on-refresh)) 
      
(fn focus [client] 
  (set _G.client.focus client)) 

{ : on-idle
  : focus} 
