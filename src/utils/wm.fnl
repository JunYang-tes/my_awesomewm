(local awful (require :awful))
(local awesome-global (require :awesome-global))
(local { : find } (require :utils.list)) 

(fn on-idle [f]
  (fn on-refresh [] 
    (pcall f) 
    (awesome-global.awesome.disconnect_signal :refresh on-refresh)) 
  (awesome-global.awesome.connect_signal :refresh on-refresh)) 
      
(fn focus [client] 
  (if client
    (set awesome-global.client.focus client))) 

(fn get-focusable-client [tag]
  (if tag
    (or (find (tag:clients ) (fn [c] c.fullscreen)) 
        (. (tag:clients) 1)))) 

{ : on-idle
  : focus 
  : get-focusable-client} 
