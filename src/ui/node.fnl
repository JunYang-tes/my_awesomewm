(import-macros {: catch
                : time-it} :utils)
(local awful (require :awful))
(local wibox (require :wibox))
(local list (require :utils.list))
(local {: assign} (require :utils.table))
(local { : atom-node
         : custom-node
         : destroy
         : find-root
         : inspect-node
         : container-node } (require :lite-reactive.node))
(local {: apply-property
        : is-observable} (require :lite-reactive.observable))
(local utils (require :utils.utils))
(local inspect (require :inspect))

(fn make-builder [Ctor props-setter]
  (local props-setter (or props-setter {}))
  (fn find-setter [prop]
    (or (. props-setter prop)
        (fn [widget value]
            (catch (.. "Failed to set " prop " to " (tostring value)) 
              nil
              (tset widget prop value)))))
  (fn [props]
    (let [
          props (assign {:visible true}
                        (or props {}))
          initial-props (collect [k v (pairs props)]
                          k
                          (if (is-observable v)
                            (v)
                            v))
          widget (Ctor initial-props)
          disposeable (icollect [k v (pairs props)]
                        (apply-property 
                          v 
                          (utils.catch (fn [value old]
                                        ((find-setter k) widget value old)))))]
      widget)))

(fn event-props [events]
  (collect [_ [prop event-name] (ipairs events)]
    prop 
    (fn [widget cb curr]
      (if curr
        (widget:disconnect_signal curr)
        (widget:connect_signal event-name cb)))))

(local popup
  (container-node
    (make-builder (fn [props]
                    (awful.popup {:widget (wibox.widget {:text ""
                                                         :widget wibox.widget.textbox})
                                  :ontop true
                                  :visible true})))
    (fn [child popup]
      (tset popup :widget (. child 1)))))

(local events
  (event-props
    [
     [:onButtonPress "button::press"]]))
(local textbox
  (atom-node
    (make-builder (fn [props]
                    (wibox.widget.textbox props.markup))
                  events)
    :textbox))

(fn one-child-container [Ctor]
  (container-node
    (make-builder #(Ctor))
    (fn [child container]
      (print :set-child)
      (tset container :widget (. child 1)))))

{: popup
 : textbox
 :checkbox (atom-node
             (make-builder #(wibox.widget
                              {:widget wibox.widget.checkbox})))
 :background (one-child-container wibox.container.background)
 :margin (one-child-container wibox.container.margin)
 :h-flex (container-node
           (make-builder #(wibox.layout.flex.horizontal))
           (fn [children container]
             (tset container :children children)))
 :v-flex (container-node
           (make-builder #(wibox.layout.flex.vertical))
           (fn [children container]
             (tset container :children children)))}
