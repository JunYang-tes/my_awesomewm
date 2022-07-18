(local awful (require :awful))
(local stringx (require :utils.string))
(local { : some} (require :utils.list))

(local screens {})

(fn key-screen [screen]
  (screen.outputs)) 

(local inferaces 
  [
   #(stringx.starts-with $1 "HDMI-")
   #(stringx.starts-with $1 "DP-") 
   #(stringx.starts-with $1 "eDP-") 
   #(stringx.starts-with $1 "VGA-")]) 

(fn parse-interface [screen]
  (var interface screen.index)
  (each [k v (pairs (or screen.outputs {}))] 
    (if (some inferaces #($1 k)) 
        (set interface k))) 
  interface) 

(awful.screen.connect_for_each_screen 
  (fn [screen]
    (print :new-screen screen)
    (print :screen-interface (parse-interface screen)) 
    (tset screens (parse-interface screen) screen))) 
(awful.screen.disconnect_for_each_screen
  (fn [screen] 
    (print :remove-screen screen) 
    (tset screens (parse-interface screen) nil))) 
     


(fn get-prefered-screen [query]
  (if query
    (match (stringx.split query ":") 
      ["" :focused] (awful.screen.focused) 
      ["" :primary] awful.screen.primary 
      ["interface" interface] (or (. screens interface) 
                                  (awful.screen.focused)) 
      _ (awful.screen.focused)) 
    (awful.screen.focused))) 

(fn get-name [screen]
  (parse-interface screen)) 

(fn get-screens []
  screens) 

(fn calc-pos [s x y]
  (local workarea s.workarea)
  { :x (+ x workarea.x) 
    :y (+ y workarea.y)}) 

{ : get-prefered-screen
  : parse-interface 
  : get-name 
  : calc-pos 
  : get-screens} 
