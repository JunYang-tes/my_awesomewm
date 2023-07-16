(local gears (require :gears))
(local wibox (require :wibox))
(local awful (require :awful))
(local WHEEL-UP 4)
(local WHEEL-DOWN 5)
(local inspect (require :inspect))
(local { : dpi : on-idle} (require :utils.wm))
(fn scroll-bar [view-size scroll-size]
  (let [widget (wibox.widget.base.make_widget)
        size {: view-size
              : scroll-size}
        calc-size (fn []
                    (math.max
                     (dpi 20)
                     (* view-size
                        (/ view-size scroll-size))))]
    (tset widget :fit
          (fn [self ctx w h]
            (values (dpi 8)
                    (calc-size))))
    (tset widget :draw
          (fn [ctx cr w h]
            (cr:rectangle 0 0 w h)
            (cr:fill)))
    (tset widget :update-size
          (fn [view-size scroll-size]
            (tset size :view-size view-size)
            (tset size :scroll-size scroll-size)))
    widget))

;;https://awesomewm.org/apidoc/documentation/04-new-widgets.md.html
(fn scollview [props]
  (let [{: forced_width
                : forced_height} (or props {})
        delta (dpi 40)
        child-size {:width 0
                    :height 0}
        pos {:x 0
             :y 0}
        scroll-bar (scroll-bar 1 1)
        widget (wibox.widget.base.make_widget)]
    (fn get-child-size []
        (values child-size.width
                child-size.height))
    (tset widget :fit
          (fn [self ctx w h]
            (let [(w h) (widget.widget:fit ctx 100000 10000)]
              (scroll-bar widget.forced_height h)
              (tset child-size
                    :width w)
              (tset child-size
                    :height h))
            (values widget.forced_width widget.forced_height)))
    (tset widget :layout
          (fn []
            (let [(w h) (get-child-size)]
              [(wibox.widget.base.place_widget_at
                 widget.widget
                 pos.x pos.y
                 w h)])))
               ; (wibox.widget.base.place_widget_at
               ;   scroll-bar
               ;   0 0
               ;   w h)])))
    (tset widget :before_draw_children
          (fn [_ ctx cr]
            (gears.shape.rectangle
              cr
              widget.forced_width
              widget.forced_height)
            (cr:clip)))
    (tset widget :forced_width forced_width)
    (tset widget :forced_height forced_height)
    (widget:buttons
      (awful.util.table.join
        (awful.button
          {}
          WHEEL-UP
          (fn []
            (let [(_ h) (get-child-size)
                  new-y (+ pos.y delta)]
              (tset pos
                    :y (math.min (+ pos.y delta)
                                 0))
              (widget:emit_signal :widget::layout_changed))))
        (awful.button
          {}
          WHEEL-DOWN
          (fn []
            (let [(_ h) (get-child-size)]
              (tset pos
                    :y (math.max (- pos.y delta)
                                 (- widget.forced_height h)))
              (widget:emit_signal :widget::layout_changed))))))
    widget))
