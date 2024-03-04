(local {: window
        : scrolled-window
        : label
        : box
        : list-box
        : button} (require :gtk4.node))
(local {: run } (require :lite-reactive.app))
(local list (require :utils.list))
(local r (require :lite-reactive.observable))
(import-macros { : time-it } :utils)
(local consts (require :gtk_.const))
(local item-count (r.value 1000))

(run
  (window
    (box
      {:orientation consts.Orientation.VERTICAL}
      (label {:label (r.map item-count
                            #(.. $1 :items))})
      (button {:label "Add Items"
               :connect_clicked (fn []
                                  (item-count (+ 1000 (item-count)))
                                  (print :click))})
      (scrolled-window
        {:vexpand true}
        (list-box
          (r.map item-count
                 (fn [count]
                   (-> (list.range 0 count)
                       (list.map (fn [i]
                                   (label {:text (.. "item " i)})))))))))))
