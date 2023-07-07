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
(local flow-box
  (container-node
    widgets.flow-box
    (fn [children container]
      (clear-child container)
      (each [i child (ipairs children)]
        (container:insert child i)))
    #$
    :flow-box))
(local grid
  (container-node
    widgets.grid
    (fn [children grid ctx]
      (clear-child grid)
      (each [_ child (ipairs children)]
        (let [def {:left 0 :top 0 :width 1 :height 1}
              layout (assign def (ctx.get-xprops child def))]
          (grid:attach child layout.left layout.top layout.width layout.height))))
      
    #$))
(local window_
       (container-node
         widgets.window
         (fn [children container ctx]
          (if (= (length children) 1)
            (tset container :child (. children 1))))
         #$
         :window))
(local scrolled-window
       (container-node
         widgets.scrolled-window
         (fn [children container ctx]
          (if (= (length children) 1)
            (tset container :child (. children 1))))
         #$))
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
(local notebook
       (container-node
         widgets.notebook
        (fn [children notebook ctx]
          (clear-child notebook)
          (each [_ child (ipairs children)]
            (let [{: title} (ctx.get-xprops child)]
              (notebook:append_page child (if title 
                                              (ctx.run title))))))
        #$))
(local event-box  
  (container-node
    widgets.event-box
    (fn [children box ctx]
      (clear-child box)
      (let [[child] children]
        (box:add child)))
    #$))
(local popover_
  (container-node
    widgets.popover
    (fn [children popover]
      ;(clear-child popover)
      ;;(popover:add (widgets.button {:label :HELLo})))
      (let [[child] children]
        (tset popover :child child)))
    #$))
(defn popover
  (let [{: visible : relative_to : children & rest } props 
        run-it (use-run)]
    (var p nil)
    (effect
      [visible relative_to children]
      (if (= p nil)
        (let [
              relative_to (relative_to)]
          (do
            (set p (run-it
                     (popover_
                       (assign rest
                         {:visible visible
                          :relative_to (relative_to)})
                       (children))))))))
    nil))

(local list-box
  (container-node
    widgets.list-box
    (fn [children list]
      (clear-child list)
      (each [i child (ipairs children)]
        (list:add child)))
    #$))
(local list-row
  (container-node
    widgets.list-row
    (fn [child row]
      (clear-child row)
      (row:add child))))
{ :button (atom-node widgets.button :Button)
  :menu-button (atom-node widgets.menu-button :MenuButton)
  :check-button (atom-node widgets.check-button :CheckButton)
  :entry (atom-node widgets.entry :Entry)
  : box
  : flow-box
  : list-row
  : list-box
  :label (atom-node widgets.label :Label)
  :image (atom-node widgets.image :Image)
  : window
  : scrolled-window
  : grid
  : notebook
  : popover
  : event-box}
 

