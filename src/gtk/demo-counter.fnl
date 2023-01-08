(local {: window
        : label
        : is-widget
        : box
        : box-item
        : check-button
        : button} (require :gtk.widgets))
(local r (require :gtk.observable))
(local counter (r.value 0))
(local win (window 
            (box
              [
                (button {:label :Dec
                         :on_clicked #(counter.set (- (counter) 1))})
                (button {:label :Inc
                         :on_clicked #(counter.set (+ (counter) 1))})
                (label {:text (r.map counter #(.. "Count:" $1))})])))
(win:show_all)


