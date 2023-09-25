(local awful (require :awful))
(local key-bindings (require :client-key-bindings))
(local beautiful (require :beautiful))
(local gears (require :gears))
(local { : modkey : mouse-button} (require :const))
(local inspect (require :inspect))

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
                   :placement (+ awful.placement.no_overlap awful.placement.no_offscreen)}
      :callback awful.client.setslave}

    { :rule_any { :role [:prompt :popup]}
      :properties {
                    :raise true
                    :floating true
                    :width 900
                    ;;:height 48
                    :ontop true
                    :placement (let [f awful.placement.top]
                                 (fn [c] (f c)))}}
    {:rule_any { :class [:kitty]}
     :callback (fn [c]
                 (if (= c.first_tag.layout.name :floating)
                   (do
                     (let [y (+ c.y 30)]
                       (tset c :y y)))))}
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
                   :ontop true
                   :keys key-bindings
                   :titlebar   true
                   :titlebars_enabled true
                   :placement (+ awful.placement.centered awful.placement.no_offscreen)
                   :floating true}}])
