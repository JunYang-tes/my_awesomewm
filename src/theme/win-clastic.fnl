(local awful (require :awful))
(local layout (require :wibox.layout))
(local {: hybrid} (require :utils.table))
(local inspect (require :inspect))
(local gears (require :gears))
(local gtable  (require "gears.table"))
(local base (require :wibox.widget.base))
(local colors
  {:primary (gears.color :#c0c0c0)
   :white (gears.color :#ffffff)
   :black (gears.color :#000)
   :gray (gears.color :gray)})
(fn make-button-widget [draw]
  (fn []
    (let [widget (base.make_widget
                   nil nil
                   {:enable_properties true})
          state {:pressed false}]
      (tset widget :fit
            (fn [self context w h]
              (print :DDD widget.forced_height widget.forced_width)
              (values w h)))
      (widget:buttons
        (awful.button {} 1
                      (fn []
                        (tset state :pressed true)
                        (widget:emit_signal :widget::redraw_needed))
                      (fn []
                        (tset state :pressed false)
                        (widget:emit_signal :widget::redraw_needed))))
      (fn draw-normal [context cr w h]
        (cr:set_source colors.primary)
        (cr:rectangle
          0 0 w h)
        (cr:fill)
        (cr:set_source colors.white)
        (cr:move_to 0 0)
        (cr:line_to w 0)
        (cr:move_to 0 0)
        (cr:line_to 0 h)
        (cr:stroke)
        (cr:set_line_width 0.5)
        (cr:set_source colors.black)
        (cr:move_to w h)
        (cr:line_to 0 h)
        (cr:move_to w h)
        (cr:line_to w 1)
        (cr:stroke)
        (if draw
          (draw context cr w h state.pressed)))
      (fn draw-pressed [context cr w h]
        (cr:set_source colors.primary)
        (cr:rectangle
          0 0 w h)
        (cr:fill)
        ;; top left
        (cr:set_source colors.black)
        (cr:move_to 0 0)
        (cr:line_to w 0)
        (cr:move_to 0 0)
        (cr:line_to 0 h)
        (cr:stroke)
        ;; top left
        (cr:set_source colors.gray)
        (cr:move_to 1 1)
        (cr:line_to (- w 1) 1)
        (cr:move_to 1 1)
        (cr:line_to 1 (- h 1))
        (cr:stroke)

        (cr:set_source colors.white)
        (cr:move_to w h)
        (cr:line_to 0 h)
        (cr:move_to w h)
        (cr:line_to w 1)
        (cr:stroke)
        (if draw
          (draw context cr w h state.pressed)))
      (tset widget :draw
            (fn [self context cr width height]
              (let [w (or widget.forced_width width)
                    h (or widget.forced_height height)]
                (if state.pressed
                  (draw-pressed context cr w h)
                  (draw-normal context cr  w h)))))
      widget)))

(local close (make-button-widget
               (fn [ctx cr w h]
                 (cr:set_line_width 2)
                 (let [sx (* w 0.3)
                       sy (* h 0.3)
                       ex (- w sx)
                       ey (- h sy)]
                   (cr:move_to sx sy)
                   (cr:line_to ex ey)
                   (cr:move_to ex sy)
                   (cr:line_to sx ey)
                   (cr:stroke)))))
(local maximize (make-button-widget
                  (fn [ctx cr w h]
                    (let [x (* w 0.4)
                          y (* h 0.2)
                          w (* w 0.4)
                          h (* h 0.4)]
                      (cr:set_line_width 1)
                      (cr:set_source colors.black)
                      (cr:rectangle x y w h)
                      (cr:stroke)
                      (cr:rectangle x y w
                                        (* h 0.2))
                      (cr:fill)))))


{: make-button-widget
 : maximize
 : close}

