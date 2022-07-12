(local awesome-global (require :awesome-global))
(local wm (require :utils.wm))

;; When a client exited,select a client in the same tag focus to it
(awesome-global.client.connect_signal :unmanage
  (fn [client] 
    (wm.focus (wm.get-focusable-client client.first_tag)))) 
     
