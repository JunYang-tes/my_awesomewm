(local {: window
        : label
        : hbox
        : button} (require :qt.node))
(local {: run } (require :lite-reactive.app))
(local r (require :lite-reactive.observable))
(local counter (r.value 0))

(run
  (window
    (hbox
      (button {:text "+"
               :on_clicked #(counter (+ (counter)
                                        1))})
      (label {:text (r.map counter
                           #(tostring $1))})
      (button {:text "-"
               :on_clicked #(counter (- (counter)
                                        1))}))))

