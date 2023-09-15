(local awful (require :awful))
(local layout (require :wibox.layout))
(local {: hybrid} (require :utils.table))
(local inspect (require :inspect))
(local gears (require :gears))
(local gtable  (require "gears.table"))
(local base (require :wibox.widget.base))
(local inspect (require :inspect))
(local colors
  {:primary (gears.color :#d4d0c8)
   :white (gears.color :#ffffff)
   :line-white (gears.color :#ebebeb)
   :black (gears.color :#000)
   :gray (gears.color :gray)})

(fn polygon [cr points]
  (let [[first & rest] points]
    (cr:move_to (. first 1)
                (. first 2))
    (each [_ [x y] (ipairs rest)]
      (cr:line_to x y))
    (cr:line_to (. first 1)
                (. first 2))))

(fn draw-border
  [depressed?
   cr width height
   border-width]
  (fn color [from tp]
    (gears.color.create_linear_pattern
      {:type "linear"
       :from [0 0]
       :to [width 0]
       :stops (if depressed?
                [[0  "#0a246a"] [1.0 "#a6caf0"]]
                [[0  "#808080"] [1.0 "#bfbfbf"]])}))
  (let [white (gears.color :#ebebeb)
        [left-top right-bottom] (if depressed?
                                  [(gears.color :#363535)
                                   white]
                                  [white
                                   (gears.color :#363535)])]
    ;left-top
    (cr:set_source left-top)
    (polygon cr
             [[0 0] [width 0] [(- width border-width)
                               border-width]
              [border-width border-width] [border-width (- height border-width)] [0 height]])
    (cr:fill)
    (cr:set_source right-bottom)
    ;right-bottom
    (polygon cr
            [[border-width (- height border-width)] [(- width border-width) (- height border-width)]
             [(- width border-width) border-width] [width 0] [width height] [0 height]])
    (cr:fill)))

(fn xp-frame []
  (let [widget (base.make_widget
                 nil
                 :xp-frame
                 {:enable_properties true})]
    (fn get-child []
      (. widget :widget))
    (tset widget :fit
          (fn [self ctx w h]
            (let [child (get-child)
                  padding 4]
              (if child
                (let [(w h) (base.fit_widget self ctx child w h)]
                  (values (+ w (* 2 padding))
                          (+ h (* 2 padding))))
                (values w h)))))
    (tset widget :draw
          (fn [self context cr width height]
            (cr:set_source colors.primary)
            (cr:rectangle
              0 0 width height)
            (cr:fill)
            (draw-border false cr width height 2)))
    (tset widget :layout
          (fn [_ _ w h]
            (let [child (get-child)]
              (if child
                [(base.place_widget_at
                   child
                   0 0
                   w h)]
                []))))
    widget))

(fn make-button-widget [draw]
  (fn []
    (let [widget (base.make_widget
                   nil nil
                   {:enable_properties true})
          state {:pressed false
                 :force_pressed false}]
      (tset widget :fit
            (fn [self context w h]
              (values w h)))
      (widget:buttons
        (awful.button {} 1
                      (fn []
                        (tset state :pressed true)
                        (widget:emit_signal :widget::redraw_needed))
                      (fn []
                        (tset state :pressed false)
                        (widget:emit_signal :widget::redraw_needed)
                        (if widget.on-release-left
                          (widget:on-release-left)))))
      (widget:connect_signal :mouse::leave
                             (fn []
                               (tset state :pressed false)
                               (widget:emit_signal :widget::redraw_needed)))
      (fn draw-normal [context cr w h]
        (cr:set_source colors.primary)
        (cr:rectangle
          0 0 w h)
        (cr:fill)
        (draw-border false cr w h 2.5)
        (if draw
          (draw context cr w h state.pressed)))
      (fn draw-pressed [context cr w h]
        (cr:set_source colors.primary)
        (cr:rectangle
          0 0 w h)
        (cr:fill)
        (draw-border true cr w h 2.5)
        (if draw
          (draw context cr w h state.pressed)))
      (tset widget :draw
            (fn [self context cr w h]
              (if (or state.pressed
                      state.force_pressed)
                (draw-pressed context cr w h)
                (draw-normal context cr  w h))))
      (tset widget :set_pressed
            (fn [_ pressed]
              (tset state :force_pressed pressed)
              (widget:emit_signal :widget::redraw_needed)))
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
                    (let [x (* w 0.3)
                          y (* h 0.2)
                          w1 (* w 0.4)
                          h1 (* h 0.4)]
                      (cr:set_line_width 1)
                      (cr:set_source colors.black)
                      (cr:rectangle x y w1 h1)
                      (cr:stroke)
                      (cr:rectangle x y w1
                                        (* h1 0.2))
                      (cr:fill)
                      (let [x (* w 0.2)
                            y (* h 0.35)]
                        (cr:rectangle x y w1 h1)
                        (cr:set_source colors.primary)
                        (cr:fill)
                        (cr:rectangle x y w1 h1)
                        (cr:set_source colors.black)
                        (cr:stroke))))))
(local minmize (make-button-widget
                 (fn [ctx cr w h]
                   (let [x-factor 0.3
                         x (* w x-factor)
                         y (* h 0.6)
                         w (* w (- 1 (* 2 x-factor)))
                         h (* h 0.1)]
                     (cr:set_source colors.black)
                     (cr:rectangle x y w h)
                     (cr:fill)))))
(local button-container
  (let [button-container (make-button-widget)]
    (fn []
      (let [widget (button-container)]
        (fn get-child []
          (. widget :widget))
        (tset widget :fit
              (fn [self ctx w h]
                (let [child (get-child)
                      padding 4]
                  (if child
                    (let [(w h) (base.fit_widget self ctx child w h)]
                      (values (+ w (* 2 padding))
                              (+ h (* 2 padding))))
                    (values w h)))))
        (tset widget :layout
              (fn [_ _ w h]
                (let [child (get-child)]
                  (if child
                    [(base.place_widget_at
                       child
                       0 0
                       w h)]
                    []))))
        widget))))

(fn systray-widget []
  (let [widget (base.make_widget
                 nil
                 nil
                 {:enable_properties true})]
    (tset widget :draw
          (fn [context cr width height]
            (if (not (?. context :wibox))
              (error :Need-wibox))
            (let [(x y) (base.rect_to_device_geometry
                          cr 0 0 width height)
                  awesome _G.awesome
                  num_entries (awesome.systray)
                  (dir_x dir_y) (cr:user_to_device_distance 1 0)
                  in_dir width
                  ortho height
                  base (if (<= (* ortho num_entries) in_dir)
                         ortho
                         (/ in_dir num_entries))]
              (awesome.systray
                context.wibox.drawin
                (math.ceil x)
                (math.ceil y)
                base
                false
                colors.primary
                false
                0))))
    (tset widget :fit
          (fn [context width height]
            (let [awesome _G.awesome
                  num_entries (awesome.systray)
                  base (if (< width height)
                         width
                         height)]
              (values base (* base num_entries)))))))


{: make-button-widget
 : button-container
 : maximize
 : minmize
 : xp-frame
 : colors
 : close}

