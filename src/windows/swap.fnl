(local awesome-global (require :awesome-global))
(local {: select-win } (require :windows.select-win)) 
(local {: focus } (require :utils.wm))                                   
(local screen-utils (require :utils.screen))

(fn lanuch []
  (local focused awesome-global.client.focus) 
  (if focused 
      (select-win {
                   :ignore-focus true 
                   :clients (screen-utils.clients)
                   :on-selected (fn [{: client}] 
                                  (focused:swap client) 
                                  (focus))}))) 
