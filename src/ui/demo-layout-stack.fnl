(local {: run } (require :lite-reactive.app))
(local {: value
        : map} (require :lite-reactive.observable))
(local wibox (require :wibox))
(local gears (require :gears))
(print (require :ui.builder))
(print (require :ui.node))
(local {: popup
        : textbox
        : place
        : progress-bar
        : stack} (require :ui.node))

(run
  (popup
    (stack
      (progress-bar {:max_value 1
                     :forced_width 200
                     :fg :#00ff00
                     :shape gears.shape.rounded_bar
                     :forced_height 50
                     :value 0.5})
      (place
        {:valign :center ;one of top center bottom}
         :halgin :center} ;left,center,right
        (textbox {:markup :50%})))))

