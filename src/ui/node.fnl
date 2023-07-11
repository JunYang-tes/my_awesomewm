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
  (tset props-setter
        :on
        (or props-setter.on
            (fn [widget [event cb]]
              (widget:connect_signal event cb))))
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
                          (if (is-observable v)
                            [k (v)]
                            [k v]))
          widget (Ctor initial-props)
          disposeable (icollect [k v (pairs props)]
                        (apply-property 
                          v 
                          (utils.catch (fn [value old]
                                        ((find-setter k) widget value old)))))]
      widget)))

(local popup
  (container-node
    (make-builder (fn [props]
                    (awful.popup {:widget (wibox.widget {:text ""
                                                         :widget wibox.widget.textbox})
                                  :ontop true
                                  :visible true})))
    (fn [child popup]
      (tset popup :widget (. child 1)))))

(local textbox
  (atom-node
    (make-builder (fn [props]
                    (wibox.widget.textbox props.markup)))
    :textbox))

{: popup
 : textbox}
