(local awful (require :awful))
(local layout (require :wibox.layout))
(local {: hybrid} (require :utils.table))
(local inspect (require :inspect))
(local gears (require :gears))
(local gtable  (require "gears.table"))
(local base (require :wibox.widget.base))
(local {: focus
        : focused} (require :utils.wm))
(local awesome-global (require :awesome-global))

(fn titlebar-color [width focus]
  (gears.color.create_linear_pattern
    {:type "linear"
     :from [0 0]
     :to [width 0]
     :stops (if focus
              [[0  "#0a246a"] [1.0 "#a6caf0"]]
              [[0  "#808080"] [1.0 "#bfbfbf"]])}))

(fn titlebar [client]
  (fn []
    (let [widget (base.make_widget nil nil {:enable_properties true})
          private {}]
      (fn get-child []
        (. private :child))
      (tset widget :fit
            (fn [self context w h]
              (let [child (get-child)]
                (if (not child)
                  (values 0 0)
                  (base.fit_widget
                    self context child w h)))))
      (tset widget :get_children
            (fn []
              [ (. widget :_child)]))
      (tset widget :set_children
            (fn [_ [child]]
              (tset  private :child child)))
      (tset widget :layout
            (fn [_ _ w h]
              (let [child (get-child)]
                (if child
                  [(base.place_widget_at
                     child
                     0 0
                     w h)]
                  []))))
      (tset widget :draw
            (fn [widget ctx cr width height]
              (cr:set_line_width 1)
              (let [focused (= client awesome-global.client.focus)]
                (cr:set_source (titlebar-color width focused)))
              (cr:rectangle 0 0 width height)
              (cr:fill)))
      (client:connect_signal :focus
                             (fn []
                               (widget:emit_signal :widget::redraw_needed)
                               (print :FFFFF)))
      widget)))



;#d4d0c8
(fn [client]
  (let [buttons (gears.table.join
                  (awful.button [] 1 (fn []
                                       (focus client)
                                       (client:raise)
                                       (awful.mouse.client.move client)))
                  (awful.button [] 3 (fn []
                                       (focus client)
                                       (client:raise)
                                       (awful.mouse.client.resize client))))
        bar (awful.titlebar client
                            {:bg_normal :#d4d0c8
                             :bg_focus :#d4d0c8})]

    (bar:setup
      (hybrid
        [(hybrid
           [(awful.titlebar.widget.iconwidget client)
            (hybrid [{:halign :center
                      :widget (awful.titlebar.widget.titlewidget client)}]
                    {: buttons :layout layout.fixed.horizontal})
            (hybrid [(awful.titlebar.widget.maximizedbutton client)
                     (awful.titlebar.widget.closebutton client)]
                    {:layout layout.align.horizontal})]
           {:layout layout.align.horizontal})]
        {:layout (titlebar client)}))
    bar))
