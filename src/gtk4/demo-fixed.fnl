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
(local x (r.value 100))
(run (window
      {:class cls}
      (fixed
        {:overflow 0
         :size [100 100]}
        (button
          {:label "X=X+10"
           :-x 50
           :connect_click (fn []
                            (x (+ (x) 10)))})
           
        (label {:text (r.map x #(.. "x:" $1))
                :-x x
                :-y 0})
        (label {:text "world"
                :-x x
                :-y 100}))))

        ; (button {:label :Button} 
        ;        :connect_clicked #(print :clicked)))))


