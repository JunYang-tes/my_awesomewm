(import-macros {: unmount : defn : onchange} :lite-reactive)
(import-macros {: global-css : css
                : global-id-css } :gtk)
(import-macros {: css-gen } :css)
(local {:gtk4 gtk
        : gtk4_css} (require :widgets))
(local {: window
        : label
        : box
        : overlay
        : check-button
        : button} (require :gtk4.node))
(local {: run } (require :lite-reactive.app))
(local r (require :lite-reactive.observable))
(local counter (r.value 0))
(local inspect (require :inspect))
(local cls (global-css
             (& " button"
                [:color :red])))
(local consts (require :gtk4.const))

(defn counter
  (local counter (r.value 1))
  (onchange [counter]
            (print (inspect old) 
                   (inspect new)))
  (overlay
    (label {:label :this-is-overlay
            :halign consts.Align.Start})
    (box
      (button {:label :Dec
                   :connect_click #(counter.set (- (counter) 1))})
      (label {:text (r.map counter #(.. "Count:" $1))})
      (button {:label :Inc
                   :connect_click #(counter.set (+ (counter) 1))}))))

(run (window
      {:class cls}
      (box
        {:orientation 1}
        (counter))))

