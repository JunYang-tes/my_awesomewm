(local {: is-observable} (require :gtk.observable))
(local {: Gtk } (require :lgi))
(local {: make-type 
        : type-of} (require :utils.type))
(local strings (require :utils.string))
(local utils (require :utils.utils))
(local {: assign
        : weak-key-table } (require :utils.table)) 
(local list (require :utils.list))

(fn is-widget [obj]
  (or (= :widget (type-of obj))
      (let [str (tostring obj)]
        (and (strings.starts-with str :lgi.obj)
             (strings.includes str :Gtk)))))

(local observer-refs (weak-key-table))
(fn apply-property [target property value setter]        
  (let [set-prop (utils.catched (or setter (fn [value] (tset target property value))))]
    (if (is-observable value)
        (do 
          (fn handle-change [new] (set-prop new))
          (tset observer-refs target handle-change)
          (set-prop (value))
          (value.add-weak-observer handle-change))
        (set-prop value))))

(fn is-array [obj]  
  (and (= (type obj) :table)
       (not= nil (. obj 1))))

(fn is-props-table [obj]
  (and (= (type obj) :table)
       (not (list.is-list obj))))

(local widget-extra-props (weak-key-table))

(local widget-type (make-type :widget)) 
(fn make-children [child]
  (list.flatten (if (list.is-list child) child [child])))
(fn make-widget [Ctr props_setter]
  (local props_setter (or props_setter {}))
  (fn find-setter [prop]
    (or (. props_setter prop)
        (fn [widget value]
            (tset widget prop value))))
  ;; [props] | [child]
  ;; [children] | [child]
  ;; [props,children] | [child, child]
  ;; [props-or-child ...]
  (fn [...]
    (fn prepare-props [...]
      (let [all [...]]
        (if 
          (= (length all) 1)
          (let [[first] all] 
            (if (is-props-table first)
              first 
              {:children (make-children first)}))
          (= (length all ) 2)
          (let [[props children] all]
            (if (is-props-table props)
                (assign props {:children (make-children children)})
                {:children (make-children all)}))
          (let [[first & others] all]
            (if (is-props-table first)
              (if (> (length others) 0)
                (assign first {:children (make-children others)})
                first)
              {:children (make-children all)})))))
    (let [props (prepare-props ...)]
      ;; set default to visible
      (tset props :visible (utils.not-nil props.visible true))
      (let [widget (Ctr)
            extra {:on-extra-change (fn [])}]
        (each [prop value (pairs (or props {}))]
          (if (strings.starts-with prop :-)
            (let [prop (string.sub prop 2)]
              (apply-property widget prop value (fn [value]
                                                 (tset extra prop value)
                                                 (extra.on-extra-change))))
            (apply-property widget prop value (fn [value] ((find-setter prop) widget value)))))
        (tset widget-extra-props widget extra)
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
(local window (make-widget Gtk.Window
                           {:children (fn [win [child]]
                                        (assert (is-widget child) "Child of window should be a widget")
                                        (tset win :child child))}))
(local entry (make-widget Gtk.Entry))
(local scrolled-window (make-widget Gtk.ScrolledWindow
                                    {:children (fn [win [child]]
                                                (assert (is-widget child) "Child of window should be a widget")
                                                (tset win :child child))}))
(local flow-box (make-widget Gtk.FlowBox
                             {:children (fn [flow-box child]
                                         (clear-child flow-box)
                                         (let [children (if (is-widget child) [child] child)]  
                                           (each [i child (ipairs children)]
                                             (flow-box:insert child i))))}))
(local image (make-widget Gtk.Image))

(fn box-repack [widget item props]
  (widget:set_child_packing
    item
    (or props.expand false)
    (or props.fill false)
    (or props.spacing 0)
    0))
(local box (make-widget Gtk.Box
                        {
                          :homogeneous (make-setter :homogeneous)
                          :children (fn [widget value]
                                       (each [_ child (ipairs (widget:get_children))]
                                         (widget:remove child))
                                       (each [_ child (ipairs value)]
                                         (print :child-is child)
                                         (let [extra (or (. widget-extra-props child)
                                                         {:expand false
                                                          :fill false
                                                          :spacing 0})]
                                           (tset extra :on-extra-change #(box-repack widget child extra))
                                           (widget:pack_start 
                                             child 
                                             (or extra.expand false) 
                                             (or extra.fill false)
                                             (or extra.spacing 0)))))}))
(local grid 
       (make-widget 
         Gtk.Grid
         {:children 
          (fn [grid children]
             (clear-child grid)
             (each [_ child (ipairs children)]
              (let [extra (assign
                            {:left 0
                             :top 0
                             :width 1
                             :height 1}
                            (. widget-extra-props child))]
                (tset extra :on-extra-change #(grid:attach child 
                                                           extra.left
                                                           extra.top
                                                           extra.height
                                                           extra.height))
                (grid:attach child extra.left extra.top extra.width extra.height))))}))
(local label (make-widget Gtk.Label 
                          {
                            :text (make-setter :text) 
                            ;; :justify (make-setter :justify) 
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
 : grid
 : is-widget
 : make-widget
 : apply-property}
 
