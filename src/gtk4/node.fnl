(import-macros {: catch
                : time-it} :utils)
(import-macros {: defn
                : unmount
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
            all_widgets {}
            widgets {}
            counter {:create 1}
            render (props.render)
            run (use-run)
            on-built (use-built)
            setup (fn []
                    (do
                      (let [props (observable.of (. (props.data) 1))
                            child (run (render props) true)]
                        (tset items child props)
                        child)))
            bind (fn [child i]
                   (let [data_items (props.data)
                         item_props (. items child)]
                     (item_props (. data_items i))))
            item_factory (gtk4.signal_item_factory setup bind)
            view (list-view-atom
                   {:factory item_factory})]
        (effect [props.data]
                (when (on-built)
                  (let [v (view)
                        data (props.data)]
                    (time-it "update count"
                      (v:set_model (list.range 1 (length data)))))))
        view))))


{ ;:button (atom-node widgets.button :Button)
  :entry (atom-node widgets.entry :Entry)
  : box
  ; : list-row
  ; : list-box
  : list-view
  :label (atom-node widgets.label :Label)
  ;:picture (atom-node widgets.picture :Picture)
  : window
  : scrolled-window}


