(local awful (require :awful))
(local key-bindings (require :client-key-bindings))
(local beautiful (require :beautiful))
(local gears (require :gears))
(local { : modkey : mouse-button} (require :const))
(local inspect (require :inspect))

(local activate #($1:emit_signal "request::activate" "mouse_click" { :raise true}))
(local mouse-buttons
  (gears.table.join
    (awful.button [] mouse-button.left 
                  (fn [client]
                    (print :left)
                    (activate client)
                    (let [ geometry (client:geometry)
                          cx geometry.x
                          cy geometry.y
                          cw geometry.width
                          ch geometry.height
                          delta 6
                          mouse-coords (_G.mouse.coords)
                          mx mouse-coords.x
                          my mouse-coords.y
                          close-to-border (or (< (math.abs (- cx mx))
                                                 delta)
                                              (< (math.abs (- cy my))
                                                 delta)
                                              (< (math.abs (- (+ cx cw) mx))
                                                 delta)
                                              (< (math.abs (- (+ cy ch) my))
                                                 delta))]
                      (print close-to-border)
                      (when close-to-border
                        (awful.mouse.client.resize client)))))

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
                   :placement (+ awful.placement.no_overlap awful.placement.no_offscreen)}
      :callback awful.client.setslave}

    { :rule_any { :role [:cmd-palette :popup]}
      :properties {
                    :raise true
                    :floating true
                    :borderless true
                    :width 900
                    ;;:height 48
                    :ontop true
                    :placement (let [f awful.placement.top]
                                 (fn [c] (f c)))}}
    ;; If a client's size hints is static, when floating, the title bar is out of screen
    ;; don't know why. move it down a little bit.
    {:rule {}
     :callback (fn [c]
                 (if (and (= c.first_tag.layout.name :floating)
                          (= c.size_hints.win_gravity :static))
                   (do
                     (let [y (+ c.y 40)]
                       (tset c :y y)))))}
    {:rule_any {:type [:dock
                       :tooltip
                       :menu]}
     :properties {:raise true
                  :floating true}}
    ;; Floating
    { :rule_any {
                 :instance [ "DTA" "copyq" "pinentry"]
                 :class ["Arandr" "Blueman-manager"
                         "Gpick" "Kruler"
                         "MessageWin" "Sxiv" "Wpa_gui" "veromix"
                         "xtightvncviewer"]
                 :name ["Event Tester"]
                 :type [:dialog]
                 :role ["AlarmWindow" "ConfigManager" "pop-up"]}
      :properties {
                   :border_width 1
                   :raise true
                   :ontop (fn [client]
                            (let [tag client.first_tag]
                              ;Don't set ontop if current tag layout is floating
                              (not (= tag.layout.name :floating))))
                   :keys key-bindings
                   :titlebar   true
                   :titlebars_enabled true
                   :placement (+ awful.placement.centered awful.placement.no_offscreen)
                   :floating true}}])
