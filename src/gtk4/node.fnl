(import-macros {: catch
                : time-it} :utils)
(import-macros {: defn
                : unmount
                : onchange
                : effect } :lite-reactive)
(local { : atom-node
         : custom-node
         : destroy
         : find-root
         : inspect-node
         : container-node } (require :lite-reactive.node))
(local { : use-destroy
         : use-built
         : use-run } (require :lite-reactive.app))
(local inspect (require :inspect))
(local widgets (require :gtk4.widgets))
;(local gtk4 (. (require :widgets) :gtk4))
(local gtk4 (require :libgtk-lua))
(local {: assign } (require :utils.table))
(local observable (require :lite-reactive.observable))
(local list (require :utils.list))
(fn clear-child [widget]
  (if widget.remove_all_children
    (widget:remove_all_children)))
(local box
       (container-node
         widgets.box
          (fn [children container ctx]
            (clear-child container)
            (each [_ child (ipairs children)]
                 (container:append
                   child)))
          #$
          :box))
(local window_
       (container-node
         widgets.window
         (fn [children container ctx]
          (if (= (length children) 1)
            (container:set_child (. children 1))))
                                    
         #$
         :window))
(local scrolled-window
       (container-node
         widgets.scrolled-window
         (fn [children container ctx]
          (if (= (length children) 1)
            (container:set_child (. children 1))))
         #$))
(local window
 (custom-node
   (fn [props]
    (let [{: keep-alive : children & rest} props
          destroy (use-destroy)
          win (window_
                (assign
                  {:connect_close_request
                   (if (observable.get keep-alive)
                    (fn [] true)
                    (fn []
                      (destroy)))}
                  rest)
                children)]
      win))
   :window))
(local list-box
  (container-node
    widgets.list-box
    (fn [children list]
      (time-it "Recreate list"
        (clear-child list)
        (each [i child (ipairs children)]
          (list:append child))))
    #$))
(local list-row
  (container-node
    widgets.list-row
    (fn [children row]
      (row:set_child (. children 1)))))
(local list-view-atom
  (atom-node widgets.list-view))
(local list-view
  (custom-node
    ;; props:
    ;;   render: render item ,not reactive
    ;;   data: list data
    ;;
    (fn [props]
      (let [items {}
            data_size (observable.map props.data #(if (= nil $1)
                                                    0
                                                    (length $1)))
            widget_pool {}
            bind_children []
            counter {:create 1}
            render (props.render)
            run (use-run)
            on-built (use-built)
            setup (fn []
                    (if (> (length widget_pool) 0)
                      (let [child (. widget_pool (length widget_pool))]
                        (table.remove widget_pool)
                        child)
                      (let [data_item (. (props.data ) 1)
                            _ (tset data_item :_data_index 1)
                            props (observable.of data_item)
                            child (run (render props 1) true)]
                        (tset items (child:address) props)
                        child)))
            bind (fn [child i]
                   (let [data_items (props.data)
                         idx (tonumber i)
                         child_addr (child:address)
                         item_props (. items (child:address))
                         data_item (. data_items idx)]
                     (table.insert bind_children [idx child_addr])
                     (tset data_item :_data_index idx)
                     (item_props data_item)))
            unbind (fn [_ i]
                     (let [idx (tonumber i)]
                       (list.remove-value-by! 
                         bind_children
                         (fn [[i _addr]]
                           (= i idx)))))
                       
            rebind (fn []
                     (each [_ [idx child_addr] (ipairs bind_children)]
                       (let [item_props (. items child_addr)
                             data_items (props.data)
                             data_item (. data_items idx)]
                         (tset data_item :_data_index idx)
                         (item_props data_item))))
            teardown (fn [child]
                       (table.insert widget_pool child))
            item_factory (gtk4.signal_item_factory setup bind teardown unbind)
            view (list-view-atom
                   {:factory item_factory
                    :show_separators props.show_separators})]
        
        (effect [on-built]
                (when (on-built)
                  (let [v (view)
                        data (props.data)]
                    (v:set_model (list.range 1 (+ 1 (length data)))))))
        (onchange [props.data]
                  (let [[old] old
                        [new] new
                        v (view)
                        old-size (length old)
                        new-size (length new)]
                    (if (= old new)
                      (rebind); rebind to keep listview interal state,e.g.,scroll position
                      (v:update_model (list.range 1 (+ 1 (length new)))))))
        view))))


{ :button (atom-node widgets.button :Button)
  :entry (atom-node widgets.entry :Entry)
  : box
  ; : list-row
  ; : list-box
  : list-view
  :label (atom-node widgets.label :Label)
  :picture (atom-node widgets.picture :Picture)
  : window
  : scrolled-window}


