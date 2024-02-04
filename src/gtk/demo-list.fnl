(local {: Gtk} (require :lgi))
(local {: window
        : scrolled-window
        : label
        : list-box
        : box
        : check-button
        : button} (require :gtk.node))
(local {: run } (require :lite-reactive.app))
(local list (require :utils.list))
(local r (require :lite-reactive.observable))
(import-macros { : time-it } :utils)
(local item-count (r.value 1000))

(run
  (window
    (box
      {:orientation Gtk.Orientation.VERTICAL}
      (label {:label (r.map item-count
                            #(.. $1 :items))})
      (button {:label "Add Items"
               :on_clicked (fn []
                             (item-count (+ 1000 (item-count)))
                             (print :click))})
      (scrolled-window
        {:-expand true
         :-fill true}
        (list-box
          (r.map item-count
                 (fn [count]
                   (-> (list.range 0 count)
                       (list.map (fn [i]
                                   (label {:text (.. "item " i)})))))))))))
    
