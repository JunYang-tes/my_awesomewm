(local awful (require :awful))
(local awesome-global (require :awesome-global))
(local wm (require :utils.wm))
(local inspect (require :inspect))            

;; When a client exited,select a client in the same tag focus to it
(awesome-global.client.connect_signal :unmanage
  (fn [client] 
    (wm.focus (wm.get-focusable-client client.first_tag)))) 

(fn focus-by-direction [dir]
  (let [ client awesome-global.client.focus
         clients (if client 
                     (client.first_tag:clients) 
                     [])] 
    (print :client client)
           
    (if client 
        (wm.focus (wm.get-by-direct client clients dir))))) 

{
 : focus-by-direction}
 
