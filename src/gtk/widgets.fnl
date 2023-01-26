(local {: Gtk } (require :lgi))
(local {: apply-property
        : is-observable} (require :lite-reactive.observable))
(local strings (require :utils.string))
(local utils (require :utils.utils))
(local inspect (require :inspect))
(local {: assign} (require :utils.table))

(fn is-widget [obj]
  (let [str (tostring obj)]
    (and (strings.starts-with str :lgi.obj)
         (strings.includes str :Gtk))))
(fn make-builder [Ctor props-setter]
  (local props-setter (or props-setter {}))
  (fn find-setter [prop]
    (or (. props-setter prop)
        (fn [widget value]
            (tset widget prop value))))
  (fn [props]
    (let [
          props (assign {:visible true}
                        (or props {}))
          widget (Ctor)
          disposeable (icollect [k v (pairs props)]
                        (apply-property 
                          v 
                          (utils.catch (fn [value]
                                        ((find-setter k) widget value)))))]
      widget)))
(fn make-setter [prop]
  (fn [widget value]
      (: widget (.. "set_" prop) value)))

{
 : is-widget
 :label (make-builder Gtk.Label { :text (make-setter :text)
                                  :markup (make-setter :markup)})
 :button (make-builder Gtk.Button)
 :image (make-builder Gtk.Image)
 :entry (make-builder Gtk.Entry)
 :check-button (make-builder Gtk.CheckButton)
 :box (make-builder Gtk.Box)
 :flow-box (make-builder Gtk.FlowBox)
 :window (make-builder Gtk.Window)
 :scrolled-window (make-builder Gtk.ScrolledWindow)
 :grid (make-builder Gtk.Grid)
 :notebook (make-builder Gtk.Notebook)}
