(local {: Gtk} (require :lgi))
(local {: window
        : label
        : is-widget
        : box
        : box-item
        : check-button
        : button} (require :gtk.widgets))
(local r (require :gtk.observable))
(local btn1-expand (r.value true))
(local btn1-fill (r.value true))
(local win 
       (window
         (box
           {:orientation Gtk.Orientation.VERTICAL}
           [
            (box
              [(box-item
                 (check-button
                  {:label (r.map btn1-expand (fn [v] (.. "Button 1 expand:" (tostring v))))
                   :active btn1-expand
                   :on_toggled (fn [data]
                                 (btn1-expand.set data.active))}))
               (box-item
                 (check-button
                   {:label "Button 1 fill"
                    :active btn1-fill
                    :on_toggled (fn [btn]
                                  (btn1-fill.set btn.active))}))])
            (box 
              [(box-item
                 (button {:label :button1})
                 {:expand btn1-expand 
                  :fill btn1-fill})
               (box-item
                 (button {:label "This is button2"})
                 {:expand false :fill false})
               (box-item
                 (button {:label :button3})
                 {:expand false :fill false})])])))
(win:show_all)
