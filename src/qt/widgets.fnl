(import-macros {: catch } :utils)
(local {: qt } (require :widgets))
(local {: apply-property
        : is-observable} (require :lite-reactive.observable))
(local strings (require :utils.string))
(local list (require :utils.list))
(local utils (require :utils.utils))
(local inspect (require :inspect))


(fn make-reactive-widget [Ctor props-setter]
  (local props-setter (or props-setter {}))
  (fn find-setter [prop]
    (or (. props-setter prop)
        (fn [widget value]
          (let [f (or (. widget (.. :set_ prop))
                      (. widget prop))]
            (if f
              (f widget value)
              (print "No " prop))))))
  (fn [props]
    (let [
          ; props (assign {:visible true}
          ;               (or props {}))
          widget (Ctor)
          disposeable (icollect [k v (pairs props)]
                        (when (not= v nil)
                          (apply-property
                            v
                            (utils.catch (fn [value old]
                                          ((find-setter k) widget value old))))))]
      widget)))

{:window (make-reactive-widget qt.win)
 :button (make-reactive-widget qt.button)
 :label (make-reactive-widget qt.label)
 :line_edit (make-reactive-widget qt.line_edit)
 :list (make-reactive-widget qt.list)
 :hbox (make-reactive-widget qt.hbox)
 :vbox (make-reactive-widget qt.vbox)}
