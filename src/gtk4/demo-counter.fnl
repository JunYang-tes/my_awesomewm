(import-macros {: global-css : css
                : global-id-css } :gtk)
(import-macros {: css-gen } :css)
(local {:gtk4 gtk
        : gtk4_css} (require :widgets))
(local {: window
        : label
        : box
        : check-button
        : button} (require :gtk4.node))
(local {: run } (require :lite-reactive.app))
(local r (require :lite-reactive.observable))
(local counter (r.value 0))
(local cls (global-css
             (& " button"
                [:color :red])))
(run (window
      {:class cls}
      (box
        {:orientation 1}
        (button {:label :Dec
                 :connect_clicked #(counter.set (- (counter) 1))})
        (button {:label :Inc
                 :connect_clicked #(counter.set (+ (counter) 1))})
        (label {:label "This is a label"})
        (label {:text (r.map counter #(.. "Count:" $1))})
        (button {:label :Button 
                 :connect_clicked #(print :clicked)}))))

