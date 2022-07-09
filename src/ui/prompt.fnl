(local awful (require :awful))
(local wibox (require :wibox)) 
(local beautiful (require :beautiful))
(print :prompt-width beautiful.border_normal)
(local textbox (wibox.widget {
                              :markup "This"
                              :widget wibox.widget.textbox
                              :forced_width 400 
                              :forced_height 50})) 
                               
(local prompt-width 400)
(local popup (awful.popup 
              { :widget textbox 
                :fg :white
                :border_color beautiful.border_normal
                :border_width 2 
                :width 400
                 :ontop true 
                 :visible false 
                 :x 0 
                 :y 40})) 
(fn prompt [{: on-finished : prompt : history_path}]
                
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
     :font "Sans regular 16" 
     :exe_callback on-finished
     : history_path
     :done_callback (fn [] 
                      (set popup.visible false))})) 
                                              
{ : prompt}
