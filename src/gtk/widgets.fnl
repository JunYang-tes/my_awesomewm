(import-macros {: catch } :utils)
(local {: Gtk } (require :lgi))
(local {: apply-property
        : is-observable} (require :lite-reactive.observable))
(local strings (require :utils.string))
(local list (require :utils.list))
(local utils (require :utils.utils))
(local inspect (require :inspect))
(local {: assign} (require :utils.table))

(fn is-widget [obj]
  (let [str (tostring obj)]
    (and (strings.starts-with str :lgi.obj)
         (strings.includes str :Gtk))))
(fn make-builder [Ctor props-setter]
  (local props-setter (or props-setter {}))
  (tset props-setter :class 
        (fn [w cls old]
          (let [ctx (w:get_style_context)
                old-cls (list.filter
                          (list.flatten [old])
                          #$1)
                cls (list.filter 
                      (list.flatten [cls])
                      #$1)]
            (each [_ i (ipairs old-cls)]
              (ctx:remove_class i))
            (each [_ i (ipairs cls)]
              (ctx:add_class i)))))
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
          widget (Ctor)
          disposeable (icollect [k v (pairs props)]
                        (apply-property 
                          v 
                          (utils.catch (fn [value old]
                                        ((find-setter k) widget value old)))))]
      widget)))
(fn make-setter [prop]
  (fn [widget value]
      (: widget (.. "set_" prop) value)))

{
 : is-widget
 :label (make-builder Gtk.Label { :text (make-setter :text)
                                  :markup (make-setter :markup)})
 :button (make-builder Gtk.Button)
 :menu-button (make-builder Gtk.MenuButton)
 :image (make-builder Gtk.Image)
 :entry (make-builder Gtk.Entry {:auto-focus (fn [w auto-focus]
                                               (if auto-focus
                                                 (w:grab_focus)))})
 :check-button (make-builder Gtk.CheckButton)
 :box (make-builder Gtk.Box)
 :list-box (make-builder Gtk.ListBox)
 :list-row (make-builder Gtk.ListBoxRow)
 :flow-box (make-builder Gtk.FlowBox)
 :window (make-builder Gtk.Window {:default_size (fn [w [width height]]
                                                   (w:set_default_size width height))})
 :scrolled-window (make-builder Gtk.ScrolledWindow)
 :grid (make-builder Gtk.Grid)
 :notebook (make-builder Gtk.Notebook)
 :event-box (make-builder Gtk.EventBox)
 :popover (make-builder Gtk.Popover {:visible (fn [w visible]
                                                (if visible 
                                                    (w:popup)
                                                    (w:popdown)))})}
