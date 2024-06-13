(import-macros {: catch
                : time-it} :utils)
(local { : atom-node
         : custom-node
         : destroy
         : find-root
         : inspect-node
         : container-node } (require :lite-reactive.node))
(local { : use-destroy
         : use-run } (require :lite-reactive.app))
(local {: inspect } (require :inspect))
(local {: qt } (require :widgets))
(local widgets (require :qt.widgets))

(fn is-layout [item]
  false)


(local window
  (container-node
    widgets.window
    (fn [children container]
      (let [child (. children 1)]
        (when child
          (if is-layout
            (container:set_layout (child:as_ptr))
            (let [vbox (qt.vbox)]
              (container:set_layout (vbox:as_ptr))
              (vbox:add_widget (child:as_ptr)))))))))

(fn layout [widget]
  (container-node
    widget
    (fn [children container]
      ;(container:clear)
      (each [_ child (ipairs children)]
        (if (is-layout child)
          (container:add_layout (child:as_ptr))
          (container:add_widget
            (child:as_ptr)))))))
(local list
  (container-node
    widgets.list
    (fn [children list]
      (time-it :recreate-list
        (list:clear)
        (list:add_items
          (icollect [_ child (ipairs children)]
            (child:as_ptr)))))))
        ; (each [_ child (ipairs children)]
        ;   (list:add_item (child:as_ptr)))))))
  

(local hbox (layout widgets.hbox))
(local vbox (layout widgets.vbox))
  

{:button (atom-node widgets.button :Button)
 : hbox
 : vbox
 :label (atom-node widgets.label :Label)
 : list
 :line_edit (atom-node widgets.line_edit :LineEdit)
 : window}
