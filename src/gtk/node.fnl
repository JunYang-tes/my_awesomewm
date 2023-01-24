(local { : atom-node
         : custom-node
         : container-node } (require :lite-reactive.node))
(local widgets (require :gtk.widgets))
(local {: assign } (require :utils.table))
(fn clear-child [widget]
  (each [_ child (ipairs (widget:get_children))]
    (widget:remove child)))
(local box 
       (container-node 
         widgets.box
         (fn [children container ctx]
           (clear-child container)
           (each [_ child (ipairs children)]
              (let [def {:expand false :fill false :spacing 0}
                    layout-props (assign 
                                   def
                                   (ctx.get-xprops child def))]
                (container:pack_start
                  child
                  layout-props.expand
                  layout-props.fill
                  layout-props.spacing))))
         (fn [container w ctx]
          (let [def {:expand false :fill false :spacing 0}
                layout-props (assign 
                               def
                               (ctx.get-xprops w def))]
            (container:set_child_packing
              w layout-props.expand layout-props.fill layout-props.spacing 0)))))
          
(local window
       (container-node
         widgets.window
         (fn [children container ctx]
          (if (= (length children) 1)
            (tset container :child (. children 1))))
         #$))

{ :button (atom-node widgets.button)
  :check-button (atom-node widgets.check-button)
  :entry (atom-node widgets.entry)
  : box
  :label (atom-node widgets.label)
  : window}
  
