(local {: is-observable} (require :gtk.observable))
(local {: Gtk } (require :lgi))
(local {: make-type 
        : type-of} (require :utils.type))
(local strings (require :utils.string))
(local utils (require :utils.utils))

(fn is-widget [obj]
  (or (= :widget (type-of obj))
      (let [str (tostring obj)]
        (and (strings.starts-with str :lgi.obj)
             (strings.includes str :Gtk)))))

(fn apply-property [target property value setter]        
  (let [set-prop (or setter (fn [value] (tset target property value)))]
    (if (is-observable value)
        (do 
          (set-prop (value))
          (value.add-observer (fn [new] (set-prop new))))
        (set-prop value))))

(fn is-array [obj]  
  (and (= (type obj) :table)
       (not= nil (. obj 1))))
(local widget-type (make-type :widget)) 
(fn make-widget [Ctr props_setter]
  (local props_setter (or props_setter {}))
  (fn find-setter [prop]
    (or (. props_setter prop)
        (fn [widget value]
            (tset widget prop value))))
  (fn [props child]
    (let [props (if (not= nil child)
                    (do (tset props :child child)
                        props)
                    (or (is-widget props)
                        (is-observable props)
                        (is-array props))
                    {:child props}
                    props)]
      ;; set default to visible
      (tset props :visible (utils.not-nil props.visible true))

      (let [widget (Ctr)]
        (each [prop value (pairs (or props {}))]
          (apply-property widget prop value (fn [value] ((find-setter prop) widget value))))
        (widget-type.mark-it widget)
        widget))))
(fn make-setter [prop]
  (fn [widget value]
      (: widget (.. "set_" prop) value)))
(fn clear-child [widget]
  (each [_ child (ipairs (widget:get_children))]
    (widget:remove child)))
(fn child-type [obj]
  (let [t (type-of obj)]
    (if (= t :unknown)
        (if (is-widget t)
          :widget
          :unknown)
        t)))

(local button (make-widget Gtk.Button))
(local check-button (make-widget Gtk.CheckButton))
(local window (make-widget Gtk.Window))
(local entry (make-widget Gtk.Entry))
(local scrolled-window (make-widget Gtk.ScrolledWindow))
(local flow-box (make-widget Gtk.FlowBox
                             {:child (fn [flow-box child]
                                      (clear-child flow-box)
                                      (let [children (if (is-widget child) [child] child)]  
                                        (each [i child (ipairs children)]
                                          (flow-box:insert child i))))}))
(local image (make-widget Gtk.Image))

(local box-item-type (make-type "box-item"))  
(fn box-item [widget props]
  (fn re-packing [r]
    (let [parent (widget:get_parent)]
      (if (not= nil parent)
        (do
          (parent:set_child_packing
            widget
            r.expand
            r.fill
            r.spacing
            0)))))
        
  (let [
        props (or props {})
        r {: widget}]
    (each [_ [prop def] (ipairs [ 
                                  [:expand true]
                                  [:fill true]
                                  [:spacing 0]])]
      (apply-property
        r prop (utils.not-nil (. props prop) def)
        (fn [value]
          (tset r prop value)
          (re-packing r))))
    
    (box-item-type.mark-it r)
    r))
(local box (make-widget Gtk.Box
                        {
                          :homogeneous (make-setter :homogeneous)
                          :child (fn [widget value]
                                    (each [_ child (ipairs (widget:get_children))]
                                      (widget:remove child))
                                    (match (child-type value)
                                      :box-item (widget:pack_start value.widget value.expand value.fill value.spacing)
                                      :widget (widget:pack_start value true true 0)
                                      ;; let's suppose it is list of box-item/widget
                                      _ (each [_ child (ipairs value)]
                                          (print :here child)
                                          (if (box-item-type.is child)
                                              (widget:pack_start child.widget child.expand child.fill child.spacing)
                                              (widget:pack_start child true true 0)))))}))
(local grid-item-type (make-type :grid-item))                         
(fn grid-item [props widget]
  (fn re-attach [r]
    (let [parent (widget:get_parent)]
      (if (not= nil parent)
        (parent:attach widget r.left r.top r.width r.height))))
  (let [ props (or props {})
         r {: widget}]
    (each [_ prop (ipairs [ :left :top :width :height])]
      (apply-property
        r prop (. props prop)
        (fn [value]
          (print :grid-item prop value)
          (tset r prop value)
          (re-attach))))
    (grid-item-type.mark-it r)
    r))
(local grid (make-widget Gtk.Grid
                         {:child (fn [grid child]
                                    (clear-child grid)
                                    (let [children (if (is-array child) child [child])]
                                      (each [_ child (ipairs children)]
                                        (print :grid-child child.widget)
                                        (grid:attach child.widget child.left child.top child.width child.height))))}))
(local label (make-widget Gtk.Label 
                          {
                            :text (make-setter :text) 
                            :justify (make-setter :justify) 
                            ;; :xalign (make-setter :xalign)
                            ;; :yalign (make-setter :yalign)
                            :markup (make-setter :markup)}))
                          

{: button
 : window
 : scrolled-window
 : entry
 : image
 : label
 : check-button
 : box
 : flow-box
 : box-item
 : grid
 : grid-item
 : is-widget}
 
