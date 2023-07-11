(local {: run } (require :lite-reactive.app))
(local {: value
        : map} (require :lite-reactive.observable))
(local wibox (require :wibox))
(print (require :ui.builder))
(print (require :ui.node))
(local {: popup
        : textbox
        : checkbox
        : margin
        : h-flex
        : background} (require :ui.node))

(let [cnt (value 0)]
  (run
    (popup
      (margin
        {:left 30}
        (h-flex
          {:spacing 30}
          (background
            {:bg :#ff0000}
            (textbox
              {:markup (map cnt #(.. :Hello $1))
               :onButtonPress
                       (fn []
                         (cnt (+ (cnt) 1)))}))
          (checkbox )
          (background
            {:bg :#00ff00}
            (textbox
              {:markup :world})))))))

