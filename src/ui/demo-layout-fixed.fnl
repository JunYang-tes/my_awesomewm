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
        : h-fixed
        : v-fixed
        : background} (require :ui.node))

(let [cnt (value 0)]
  (run
    (popup
      (v-fixed
         {:spacing 20}
         (h-fixed
           {:spacing 20}
           (textbox {:markup :Hello})
           (textbox {:markup :Word}))
         (textbox {:markup :HELO})
         (h-fixed
           {:spacing 20}
           (textbox {:markup :Hello})
           (textbox {:markup :Word}))))))

