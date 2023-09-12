(local wibox (require :wibox))
(local awful (require :awful))
(local {: hybrid} (require :utils.table))
(local {: run } (require :lite-reactive.app))
(local {: value
        : map} (require :lite-reactive.observable))
(local wibox (require :wibox))
(print (require :ui.builder))
(print (require :ui.node))
(local {: wibar
        : textbox
        : checkbox
        : events
        : factory
        : popup
        : place
        : margin
        : imagebox
        : h-flex
        : h-fixed
        : v-fixed
        : background} (require :ui.node))
(local {: colors
        : button-container
        : xp-frame } (require :theme.win-clastic.utils))
(local win-utils (require :theme.win-clastic.utils))
(local base (require :wibox.widget.base))
(local { : dpi } (require :utils.wm))
(local beautiful (require :beautiful))

(local button (factory.one-child-container
                button-container
                events))
(local {: get-codebase-dir} (require :utils.utils))
(local xp-frame (factory.one-child-container win-utils.xp-frame))


(local container
  (factory.one-child-container
    (fn titlebar-container []
      (let [widget (base.make_widget nil nil {:enable_properties true})
            private {}]
        (fn get-child []
          (. widget :widget))
        (tset widget :draw
              (fn [_ ctx cr width height]
                (cr:set_source colors.primary)
                (cr:rectangle 0 0 width height)
                (cr:fill)
                (cr:set_line_width 2)
                (cr:set_source colors.line-white)
                (cr:move_to 0 0)
                (cr:line_to width 0)
                (cr:stroke)))
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

(fn get-asset [name]
  (..
     (get-codebase-dir)
     "/theme/win-clastic/"
     name))




(fn titlebar [screen]
  (let [cnt (value 0)
        start-menu-visible (value true)]
    (run
      (popup
        {:visible start-menu-visible}
        (margin
          (xp-frame
            (background
              {:fg :#ff0000}
              (textbox {:markup :hello}))))))
          ; (xp-frame
          ;   {:forced_width 200}
          ;   {:forced_height 200}))))
    (run
      (wibar
        {: screen
         :height (dpi 30)
         :ontop true
         :position :bottom}
        ;(container)
        (margin
          (container
            (h-fixed
              (margin
                {:left 4}
                (place
                  {:halign :center}
                  (button
                    {
                     :forced_width 150
                     :onButtonPress (fn []
                                      (start-menu-visible (not (start-menu-visible)))
                                      (print :press))
                     :forced_height (dpi 24)}
                    (h-fixed
                      (margin
                        {:left (dpi 4)}
                        (place
                          {:halign :center}
                          (imagebox
                            {:image (get-asset :start-icon-xp.png)
                             :forced_height (dpi 20)
                             :forced_width (dpi 20)})))
                      (place
                        {:halign :center
                         :valign :center}
                        (background
                          {:fg :#000}
                          (textbox {:markup :Start
                                    :font "Tahoma 14 bold"
                                    :halign :center}))))))))))))))
