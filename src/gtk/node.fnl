(import-macros {: catch} :utils)
(local { : atom-node
         : custom-node
         : destroy
         : find-root
         : inspect-node
         : container-node } (require :lite-reactive.node))
(local { : use-destroy } (require :lite-reactive.app))
(local inspect (require :inspect))
(local widgets (require :gtk.widgets))
(local {: assign } (require :utils.table))
(local observable (require :lite-reactive.observable))
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
                w layout-props.expand layout-props.fill layout-props.spacing 0)))
          :box))
          
(local window_
       (container-node
         widgets.window
         (fn [children container ctx]
          (if (= (length children) 1)
            (tset container :child (. children 1))))
         #$
         :window))
(local window
 (custom-node 
   (fn [props]
    (let [{: keep-alive : children & rest} props
          destroy (use-destroy)
          win (window_ 
                (assign
                  {:on_delete_event
                   (if (observable.get keep-alive)
                    (fn [] true)
                    (fn []
                      (destroy)))}
                  rest)
                children)]
      win))
   :window))

{ :button (atom-node widgets.button :Button)
  :check-button (atom-node widgets.check-button :CheckButton)
  :entry (atom-node widgets.entry :Entry)
  : box
  :label (atom-node widgets.label :Label)
  : window}
  
