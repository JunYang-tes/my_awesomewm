(local awesome-global (require :awesome-global))
(local {: select-win } (require :windows.select-win)) 
(local {: focus } (require :utils.wm))                                   

(fn lanuch []
  (local focused awesome-global.client.focus) 
  (if focused 
      (select-win {
                   :ignore-focus true 
                   :on-selected (fn [{: client}] 
                                  (focused:swap client) 
                                  (focus))}))) 
