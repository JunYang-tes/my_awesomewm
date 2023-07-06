(local {: Gtk} (require :lgi))
(local {: window
        : scrolled-window
        : label
        : list-box
        : check-button
        : button} (require :gtk.node))
(local {: run } (require :lite-reactive.app))
(import-macros { : time-it } :utils)

(print 
  (time-it
    "RUN"
    (run
      (window
        (scrolled-window
          (list-box
            [
             (label {:text "item"}) 
             (label {:text "item"}) 
             (label {:text "item"}) 
             (label {:text "item"}) 
             (label {:text "item"}) 
             (label {:text "item"}) 
             (label {:text "item"}) 
             (label {:text "item"}) 
             (label {:text "item"}) 
             (label {:text "item"}) 
             (label {:text "item"}) 
             (label {:text "item"}) 
             (label {:text "item"}) 
             (label {:text "item"}) 
             (label {:text "item"}) 
             (label {:text "item"}) 
             (label {:text "item"}) 
             (label {:text "item"}) 
             (label {:text "item"}) 
             (label {:text "item"}) 
             (label {:text "item"}) 
             (label {:text "item"}) 
             (label {:text "item"}) 
             (label {:text "item"}) 
             (label {:text "item"}) 
             (label {:text "item"}) 
             (label {:text "item"}) 
             (label {:text "item"})])))))) 
    
