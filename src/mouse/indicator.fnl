(local wibox (require :wibox))
(local {: assign!} (require :utils.table))
(local awful (require :awful))
(local {: draw-cross
        : draw-grid} (require :mouse.draw))

(fn make [x y width height grid-line-count]
  (let [indicator {: x 
                   : y
                   :panel-x 0
                   :panel-y 0
                   : width 
                   : height}
        widget (wibox.widget.base.make_widget )]
    (tset widget :fit 
          (fn []
            (values indicator.width indicator.height)))
    (tset widget :draw
          (fn [widget ctx cr]
            (let [width indicator.width
                  height indicator.height
                  dx indicator.dx
                  dy indicator.dy]
              (draw-cross cr indicator.x indicator.y)
              (cr:translate indicator.panel-x indicator.panel-y)
              (if (> width 10)
                (draw-grid cr width height grid-line-count))
              (cr:translate (- 0 indicator.panel-x) indicator.panel-y))))
    (let [popup (wibox {
                        :screen (awful.screen.focused)
                        :input_passthrough true
                        : widget
                        : width
                        : height
                        :x 0
                        :y 0
                        :ontop true
                        :visible true
                        :border_width 1
                        :bg :#ff000000
                        })]
      (tset indicator :update
            (fn [panel-info position]
              (assign! indicator
                       {:x position.x
                        :y position.y
                        :width panel-info.width
                        :height panel-info.height
                        :panel-x panel-info.x
                        :panel-y panel-info.y})
              (popup:set_bg :#ff000000)))
      (tset indicator :close
            (fn []
              (tset popup :visible false)))
      indicator)))

{ : make }
