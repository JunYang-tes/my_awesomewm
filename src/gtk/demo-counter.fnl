(local {: Gtk} (require :lgi))
(local {: window
        : label
        : box
        : check-button
        : button} (require :gtk.node))
(local {: run } (require :lite-reactive.app))
(local r (require :lite-reactive.observable))
(local counter (r.value 0))
(run (window 
      (box
        (button {:label :Dec
                 :on_clicked #(counter.set (- (counter) 1))
                 :-expand true
                 :-fill true})
        (button {:label :Inc
                 :on_clicked #(counter.set (+ (counter) 1))
                 :-expand true
                 :-fill true})
        (label {:text (r.map counter #(.. "Count:" $1))
                 :-expand true
                 :-fill true}))))

