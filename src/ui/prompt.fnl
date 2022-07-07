(local awful (require :awful))
(local wibox (require :wibox)) 

(local textbox (wibox.widget {
                              :widget wibox.widget.textbox
                              :forced_width 400})) 
                               
(local prompt-width 400)
(local popup (awful.popup 
              { :widget textbox 
                :fg :#00ff00
                :border_color :#00ff00           
                :border_width 1 
                :width 400
                 :ontop true 
                 :visible false 
                 :x 0 
                 :y 0})) 
(fn prompt [{: on-finished : prompt}]
                
  (local s (awful.screen.focused))
  (set popup.widget textbox)
  (set popup.screen s)                         
  (set popup.visible true) 
  (local { : width } s.geometry) 
  (local x (/ (- width prompt-width) 2))
  (set popup.x x)
  (awful.prompt.run 
    {: textbox 
     : prompt
     :exe_callback on-finished
     :changed_callback #(print :change $1)
     :done_callback (fn [] 
                      (set popup.visible false))})) 
                                              
{ : prompt}
