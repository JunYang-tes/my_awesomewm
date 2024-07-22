(import-macros {: global-css : css
                : global-id-css } :gtk)
(import-macros {: css-gen } :css)
(local {:gtk4 gtk
        : gtk4_css} (require :widgets))
(local {: window
        : label
        : box
        : fixed
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
      (fixed
        {:overflow 0
         :size [100 100]}
        (label {:text "hello"}))))

        ; (button {:label :Button} 
        ;        :connect_clicked #(print :clicked)))))


