(import-macros {: catch } :utils)
(local {: fltk } (require :widgets))
(local {: apply-property
        : is-observable} (require :lite-reactive.observable))
(local strings (require :utils.string))
(local list (require :utils.list))
(local utils (require :utils.utils))
(local inspect (require :inspect))

(fn is-widget [obj]
  (let [str (tostring obj)]
    (and (strings.starts-with str :LuaWrapper))))

(fn make-reactive-widget [Ctor props-setter]
  (local props-setter (or props-setter {}))
  (fn find-setter [prop]
    (or (. props-setter prop)
        (fn [widget value]
          (let [f (. widget (.. :set_ prop))]
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

(fn pos [w [ x y]]
  (w:set_pos x y))
(fn size [w [x y]]
  (w:set_size x y))

{:window (make-reactive-widget
           fltk.win
           {: pos})
 :button (make-reactive-widget
           fltk.button
           {: pos
            : size})
 :flex (make-reactive-widget
         fltk.flex
         {: pos
          : size})
 :scroll (make-reactive-widget
           fltk.scroll
           {: pos
            : size})
 :pack (make-reactive-widget
         fltk.pack
         {: pos})}
