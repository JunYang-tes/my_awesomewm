(local { : atom-node
         : custom-node
         : destroy
         : find-root
         : inspect-node
         : container-node } (require :lite-reactive.node))
(local { : use-destroy
         : use-run } (require :lite-reactive.app))
(local {: inspect } (require :inspect))


(local {: fltk } (require :widgets))

(local widgets (require :fltk.widgets))
(local window
  (container-node
    widgets.window
    (fn [children container]
      (let [child (. children 1)]
        (when child
          (container:add (child:widget)))))))
(fn container [widget]
  (container-node
    widget
    (fn [children container]
      (container:clear)
      (each [_ child (ipairs children)]
        (container:add
          (child:widget))))))
(local pack (container widgets.pack))
(local flex (container widgets.flex))
  

{:button (atom-node widgets.button :Button)
 : flex
 : pack
 :scroll (container widgets.scroll)
 : window}
