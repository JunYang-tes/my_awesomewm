(local awful (require :awful))
(local wibox (require :wibox)) 
(local { : range : zip } (require :utils.list))                         
(local inspect (require :inspect))
(local { : on-idle } (require :utils.wm))

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
(fn close-popup [popups]
  (each [_ p (pairs popups)] 
    (set p.popup.visible false) 
    (set p.popup nil))) 

(fn normon []
  (var flag false)
  (each [_ c (ipairs (. (awful.screen.focused) :clients))] 
    (if (or c.fullscreen c.maximized c.maximized_vertical c.maximized_horizontal) 
      (do
        (set flag true)
        (set c.fullscreen false) 
        (set c.maximized false) 
        (set c.maximized_vertical false) 
        (set c.maximized_horizontal false)))) 
  flag) 

(fn select-win [fullscreen]
  (local screen (awful.screen.focused)) 
  (local popups 
    (collect [i [letter client] (ipairs (zip (range 97 (+ 97 26)) screen.clients))] 
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
          (close-popup popups))

        (match [key event] 
          ["Escape" _] (stop) 
          [_ "release"]
          (let [popup (. popups key)] 
            (if (not= popup nil) 
                (do (set _G.client.focus popup.client) 
                  (if fullscreen 
                      (set popup.client.fullscreen true)) 
                  (stop)))))))))

(fn launch [make-it-fullscreen]
  (local clients (. (awful.screen.focused ) :clients)) 
  (match (length clients) 
    1 (tset (. clients 1) :fullscreen (not (. clients 1 :fullscreen))) 
    _ (if (normon) 
          (on-idle (fn [] (select-win make-it-fullscreen))) 
          (select-win make-it-fullscreen)))) 

{ : launch}
