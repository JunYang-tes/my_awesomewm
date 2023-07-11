(local {: run } (require :lite-reactive.app))
(local {: value
        : map} (require :lite-reactive.observable))
(local wibox (require :wibox))
(print (require :ui.builder))
(print (require :ui.node))
(local {: popup
        : textbox} (require :ui.node))

(let [cnt (value 0)]
  (run
    (popup
      (textbox
        {:markup (map cnt #(.. :Hello $1))
         :onButtonPress
                         (fn []
                           (cnt (+ (cnt) 1)))}))))

