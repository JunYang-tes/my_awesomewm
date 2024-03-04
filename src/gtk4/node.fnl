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
         : use-run } (require :lite-reactive.app))
(local inspect (require :inspect))
(local widgets (require :gtk4.widgets))
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
      (clear-child list)
      (each [i child (ipairs children)]
        (list:append child)))
    #$))
(local list-row
  (container-node
    widgets.list-row
    (fn [children row]
      (row:set_child (. children 1)))))
{ :button (atom-node widgets.button :Button)
  :entry (atom-node widgets.entry :Entry)
  : box
  : list-row
  : list-box
  :label (atom-node widgets.label :Label)
  : window
  : scrolled-window}


