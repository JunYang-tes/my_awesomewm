(local awful (require :awful))
(local wibox (require :wibox)) 
(local { : range : zip : filter } (require :utils.list))                         
(local awesome-global (require :awesome-global)) 

(fn close-popup [popups]
  (each [_ p (pairs popups)] 
    (set p.popup.visible false) 
    (set p.popup nil))) 

(fn show-mark-popup [letter client]
  (awful.popup {
                :widget {
                         :text (string.upper letter)
                         :widget wibox.widget.textbox 
                         :align :center 
                         :valign :center 
                         :font "Sans regular 20" 
                         :forced_height 30 
                         :forced_width 30} 
                         
                :fg :#00ff00 
                :border_color :#00ff00           
                :border_width 1 
                :ontop true 
                :visible true 
                :x client.x             
                :y client.y})) 

(fn select-win [{: ignore-focus : on-selected}]
  (local screen (awful.screen.focused)) 
  (local clients
     (if ignore-focus 
        (filter screen.clients #(not= $1 awesome-global.client.focus)) 
        screen.clients)) 
  (local popups 
    (collect [i [letter client] (ipairs (zip (range 97 (+ 97 26)) clients))] 
      (values 
        (string.char letter) 
        {:popup (show-mark-popup (string.char letter) client) 
         : client
         : letter}))) 
  (local grabber 
    (awful.keygrabber.run 
      (fn [_ key event] 
        (fn stop [] 
          (awful.keygrabber.stop grabber) 
          (print :close-popup)
          (close-popup popups))

        (match [key event] 
          ["Escape" _] (stop) 
          [_ "release"]
          (let [popup (. popups (string.lower key))] 
            (if (not= popup nil) 
                (do 
                  (on-selected popup)
                  (stop)))))))))
{ : select-win}                                
