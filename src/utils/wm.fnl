(local {: awesome} (require :awesome-global))

(fn on-idle [f]
  (fn on-refresh [] 
    (pcall f) 
    (awesome.disconnect_signal :refresh on-refresh)) 
  (awesome.connect_signal :refresh on-refresh)) 
      
{ : on-idle }
