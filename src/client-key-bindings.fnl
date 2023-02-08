(local awful (require :awful))
(local { : key : tag } (require :awful))
(local hotkeys-popup (require :awful.hotkeys_popup))
(local gears (require :gears))                  
(local awesome-global (require :awesome-global))
(local {: terminal : modkey} (require :const)) 
(local {: select-tag} (require :tag)) 
(local wm (require :utils.wm))
(local {: normalize-client } (require :client)) 

(gears.table.join 
  (key [modkey] :q 
       (fn [c]
         (c:kill)) 
    {:description :close-window 
     :group :client}) 
  (key [modkey "Shift"] :m 
     (fn [c]
       (select-tag { :on-selected (fn [tag]
                                    (c:move_to_tag tag) 
                                    (tag:view_only)                  
                                    (wm.focus c) 
                                    (local clients (tag:clients))
                                    (each [_ client (ipairs clients)] 
                                      (if (not= c client) 
                                          (normalize-client client)))) 
                     :prompt "Move to "})))) 
