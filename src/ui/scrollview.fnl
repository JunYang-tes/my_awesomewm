(local wibox (require :wibox))
(local awful (require :awful))
(local WHEEL-UP 4)
(local WHEEL-DOWN 5)

(fn scollview [{: forced_width
                : forced_height}]
  (let [pos {:x 0
             :y 0}
        widget (wibox.widget.base.make_widget)]
    (tset widget :forced_width forced_width)
    (tset widget :forced_height forced_height)
    (widget:add_button
      (awful.button
        {:button WHEEL-UP
         :on_press (fn []
                     (print :whellup))}))
    widget))
