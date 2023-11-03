(local awful (require :awful))
;(local wibox (require :wibox))
(local layout (require :wibox.layout))
(local {: hybrid} (require :utils.table))
(local inspect (require :inspect))
(local gears (require :gears))
(local gtable  (require "gears.table"))
(local base (require :wibox.widget.base))

(fn titlebar-color [width focus]
  (gears.color.create_linear_pattern
    {:type "linear"
     :from [0 0]
     :to [width 0]
     :stops (if focus
              [[0  "#0a246a"] [1.0 "#a6caf0"]]
              [[0  "#808080"] [1.0 "#bfbfbf"]])}))

(fn titlebar-container [client]
  (let [widget (base.make_widget nil nil {:enable_properties true})]
    (tset widget :fit
          (fn []
            (values client.width 30)))
    (tset widget :layout
          (fn [w h]
            [(base.place_widget_at
               widget.widget
               0 0
               w h)]))
    (tset widget :draw
          (fn [widget ctx cr]
              (cr:set_line_width 1)
              (cr:set_source (titlebar-color client.width true))
              (cr:rectangle 0 0 client.width 30)
              (cr:fill)))
    widget))
