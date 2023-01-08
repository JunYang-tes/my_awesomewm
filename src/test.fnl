(local {: Gtk} (require :lgi))
(local {: window
        : label
        : is-widget
        : box
        : box-item
        : button} (require :gtk.widgets))
(local r (require :gtk.observable))
(local types (require :utils.type))
(local counter1 (r.value 0))
(local counter2 (r.value 0))
(fn counter [{ : count}]
            (box 
              [ 
                (button { :label "Dec"
                          :on_clicked (fn [] (count.set (- (count ) 1)))})
                (button { :label "Inc"
                          :on_clicked (fn [] (count.set (+ (count ) 1)))})
                (label { :markup (r.map count (fn [c] (.. "Counter : <b>" c "</b>")))})]))
  
(local win (window 
            (box 
              { :orientation Gtk.Orientation.VERTICAL
                :homogeneous false
                :spacing 10}
              [ (label {:text "Counter 1"
                        :xalign 0})
                (counter { :count counter1})
                (label {:text "Counter 2"
                        :xalign 0})
                (counter { :count counter2}) 
                (label {:xalign 0
                        :text (r.mapn 
                                counter1 counter2
                                (fn [c1 c2] 
                                  (.. "Total:" (+ c1 c2))))})])))
                                        
;; (local win (window 
;;              (box (label { :label :hello}))))
(win:show_all)
