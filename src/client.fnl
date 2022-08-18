(local awful (require :awful))
(local awesome-global (require :awesome-global))
(local wm (require :utils.wm))
(local inspect (require :inspect))            

(fn normalize-client [client]
  (if (or client.fullscreen client.maximized client.maximized_vertical client.maximized_horizontal) 
      (do
       (set client.fullscreen false) 
       (set client.maximized false) 
       (set client.maximized_vertical false) 
       (set client.maximized_horizontal false) 
       true) 
      false)) 

;; When a client exited,select a client in the same tag focus to it
(awesome-global.client.connect_signal :unmanage
  (fn [client] 
    (wm.focus (wm.get-focusable-client client.first_tag)))) 

(awesome-global.client.connect_signal :manage 
  (fn [client] 
    (print :new-client) 
    (local clients (-> client 
                     (. :first_tag) 
                     (: :clients))) 
    (each [_ v (ipairs clients)] 
      (normalize-client v)))) 

(fn focus-by-direction [dir]
  (let [ client awesome-global.client.focus
         clients (if client 
                     (client.first_tag:clients) 
                     [])] 
           
    (local geometry (. (awful.screen.focused ) :geometry))
    (if client 
        (wm.focus (wm.get-by-direct client clients dir geometry))))) 

(fn tag-untaged []
  (local tag (-> (awful.screen.focused)
                 (. :tags 1))) 
  (if tag
    (each [_ c (ipairs (awesome-global.client.get))]
      (c:move_to_tag tag)) 
    (print :no-tag-yet))) 

{
 : normalize-client
 : focus-by-direction
 : tag-untaged} 
 
