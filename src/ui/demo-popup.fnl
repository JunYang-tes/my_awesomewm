(local {: run } (require :lite-reactive.app))
(local {: value
        : map} (require :lite-reactive.observable))
(local wibox (require :wibox))
(print (require :ui.builder))
(print (require :ui.node))
(local {: popup
        : textbox
        : checkbox
        : button
        : margin
        : h-flex
        : h-fixed
        : v-fixed
        : background} (require :ui.node))

(let [cnt (value 0)]
  (run
    (popup
      (margin
        {:left 30}
        (v-fixed
          (h-fixed
            {:spacing 30
             :max_widget_size 100}
            (background
              {:bg :#ff0000}
              (textbox
                {:markup (map cnt #(.. :Hello $1))
                 :onButtonPress
                         (fn []
                           (cnt (+ (cnt) 1)))}))
            (button
              {:onButtonPress (fn []
                                (print :hello))})
            (background
              {:bg :#00ff00}
              (textbox
                {:markup :world}))
           (textbox {:markup :Hello})
           (h-fixed
             (textbox {:markup :Hello})
             (textbox {:markup :again}))))))))

