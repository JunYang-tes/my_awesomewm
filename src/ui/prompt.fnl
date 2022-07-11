(local awful (require :awful))
(local wibox (require :wibox)) 
(local beautiful (require :beautiful))
(local builder (require :ui.builder))
(local {: find} (require :utils.list))
(print :prompt-width beautiful.border_normal)
 
(local prompt-width 400)
(local popup (awful.popup 
              { :widget 
                  (wibox.widget 
                    (builder.layout.fixed-horizontal {:forced_width prompt-width}
                      (builder.container.margin {:right 10 :left 10}
                        (builder.widget.textbox {
                                                 :-id "prompt-tb"
                                                 :markup ">" 
                                                 :font "14"})) 
                      (builder.container.margin {:right 10}
                        (builder.widget.textbox {
                                                 :-id "input-tb"
                                                 :ellipsize :start
                                                 :forced_height 50})))) 
                                                  
                :fg :white
                :border_color beautiful.border_normal
                :border_width beautiful.border_width 
                :shape beautiful.prompt-shape 
                :width 400
                :ontop true 
                :visible false 
                :x 0 
                :y 40})) 
(local prompt-tb
  (-> (popup.widget:get_all_children) 
    (find #(= (. $1 :-id) "prompt-tb")))) 

(local textbox
  (-> (popup.widget:get_all_children) 
    (find #(= (. $1 :-id) "input-tb")))) 

(fn prompt [{: on-finished : prompt : history_path}]
  (local s (awful.screen.focused))
  (set popup.screen s)                         
  (set popup.visible true) 
  (local { : width } s.geometry) 
  (local x (/ (- width prompt-width) 2))
  (set popup.x x)
  (set prompt-tb.markup (or prompt ">")) 

  (awful.prompt.run 
    {: textbox 
     :font "Sans regular 14" 
     :exe_callback on-finished
     :fg_cursor beautiful.wibar_bg
     :bg_cursor beautiful.xforeground
     : history_path
     :done_callback (fn [] 
                      (set popup.visible false))})) 
                                              
{ : prompt}
