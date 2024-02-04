(local {: gtk} (require :widgets))
(local {: window
        : label
        : box
        : check-button
        : button} (require :gtk_.node))
(local {: run } (require :lite-reactive.app))
(local r (require :lite-reactive.observable))
(local counter (r.value 0))
(run (window
      (box
        {:orientation 1}
        (button {:label :Dec
                 :connect_clicked #(counter.set (- (counter) 1))
                 :-expand true
                 :-fill true})
        (button {:label :Inc
                 :connect_clicked #(counter.set (+ (counter) 1))
                 :-expand true
                 :-fill true})
        (label {:text (r.map counter #(.. "Count:" $1))
                 :-expand true
                 :-fill true}))))

