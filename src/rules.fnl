(local awful (require :awful))
(local key-bindings (require :client-key-bindings))
(local beautiful (require :beautiful))
(local gears (require :gears))                  
(local { : modkey : mouse-button} (require :const))                    
          

(local activate #($1:emit_signal "request::activate" "mouse_click" { :raise true}))
(local mouse-buttons
  (gears.table.join
    (awful.button [] mouse-button.left activate) 
    (awful.button [modkey] mouse-button.left 
      (fn [c]
        (activate c) 
        (awful.mouse.client.move c))) 
    (awful.button [modkey] mouse-button.right 
      (fn [c]
        (activate c) 
        (awful.mouse.client.resize c))))) 

(tset 
  awful.rules 
  :rules 
  [
    { :rule {}
      :properties {
                   :border_width 0
                   :border_color beautiful.xforeground
                   :focus awful.client.focus.filter
                   :raise true
                   :keys key-bindings
                   :buttons mouse-buttons
                   :screen awful.screen.preferred
                   ;;:titlebars_enabled false
                   :placement (+ awful.placement.no_overlap awful.placement.no_offscreen)}}
    ;; Floating              
    { :rule_any {
                 :instance [ "DTA" "copyq" "pinentry"]
                 :class ["Arandr" "Blueman-manager"
                         "Gpick" "Kruler"
                         "MessageWin" "Sxiv" "Wpa_gui" "veromix"
                         "xtightvncviewer"]
                 :name ["Event Tester"]          
                 :role ["AlarmWindow" "ConfigManager" "pop-up"]}
      :properties {
                   :floating true
                   :titlebars_enabled true}}])
