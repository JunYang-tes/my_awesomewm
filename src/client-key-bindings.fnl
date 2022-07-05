(local awful (require :awful))
(local { : key : tag } (require :awful))
(local hotkeys-popup (require :awful.hotkeys_popup))
(local focus-win (require :focus-win))
(local gears (require :gears))                  
(local awesome-global (require :awesome-global))
(local {: terminal : modkey} (require :const)) 

(gears.table.join 
  (key [modkey "Shift"] :c 
       ;;#($1 :kill)
       (fn [c]
         (print "close")
         (c:kill)) 
    {:description :close-window 
     :group :client})) 
