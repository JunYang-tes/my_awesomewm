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
(local gtk4 (. (require :widgets) :gtk4))
(local {: assign } (require :utils.table))
(local observable (require :lite-reactive.observable))
(fn clear-child [widget]
  (if widget.remove_all_children
    (widget:remove_all_children)
    (print "Warning: no remove_all_children find in " widget)))
(local box
       (container-node
         widgets.box
          (fn [children container ctx]
            (clear-child container)
            (each [_ child (ipairs children)]
                 (container:append
                   (child:as_ptr))))
          #$
          :box))
(local window_
       (container-node
         widgets.window
         (fn [children container ctx]
          (if (= (length children) 1)
            (container:set_child (: (. children 1)
                                    :as_ptr))))
         #$
         :window))
(local scrolled-window
       (container-node
         widgets.scrolled-window
         (fn [children container ctx]
          (if (= (length children) 1)
            (container:set_child (: (. children 1)
                                    :as_ptr))))
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
          (list:append (child:as_ptr)))))
    #$))
(local list-row
  (container-node
    widgets.list-row
    (fn [children row]
      (row:set_child (: (. children 1) :as_ptr)))))
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
            view (list-view-atom
                   {:item_factory (fn []
                                    ; (let [box4 (gtk4.box)
                                    ;       ptr (box4:as_ptr)
                                    ;       label (gtk4.label)
                                    ;       desc (gtk4.label)
                                    ;       desc_ptr (desc:as_ptr)]
                                    ;   (box4:append (label:as_ptr))
                                    ;   (box4:append desc_ptr)
                                    ;   (tset widgets ptr desc)
                                    ;   ptr))
                                    (do
                                      (let [props (observable.of (. (props.data) 1))
                                            child (run (render props) true)]
                                        (tset all_widgets (child:as_ptr) child)
                                        (tset items (child:as_ptr) props)
                                        (child:as_ptr))))
                    ; :teardown (fn [key]
                    ;             (print :recycle)
                    ;             (table.insert widgets (. all_widgets key)))
                    ;:count (observable.map props.data #(length $1))
                    :item_updater (fn [i key]
                                    (let [data_items (props.data)
                                          item_props (. items key)]
                                      (item_props (. data_items i))))})]
        (effect [props.data]
                (when (on-built)
                  (let [v (view)]
                    (time-it "update count"
                      (v:set_count (length (props.data)))))))
        view))))


{ :button (atom-node widgets.button :Button)
  :entry (atom-node widgets.entry :Entry)
  : box
  : list-row
  : list-box
  : list-view
  :label (atom-node widgets.label :Label)
  :picture (atom-node widgets.picture :Picture)
  : window
  : scrolled-window}


