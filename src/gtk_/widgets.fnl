(import-macros {: catch } :utils)
(local {: gtk} (require :widgets))
(local {: apply-property
        : is-observable} (require :lite-reactive.observable))
(local strings (require :utils.string))
(local list (require :utils.list))
(local utils (require :utils.utils))
(local inspect (require :inspect))
(local {: assign} (require :utils.table))

(fn is-widget [obj]
  (let [str (tostring obj)]
    (and (strings.starts-with str :LuaWrapper))))
(fn make-builder [Ctor props-setter]
  (local props-setter (or props-setter {}))
  (tset props-setter :class 
        (fn [w cls old]
          (let [ctx (w:style_context)
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
            (let [f (or (. widget (.. :set_ prop))
                        ;connect_xx
                        (. widget prop))]
              (f widget value))))))
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
      (widget:show)
      widget)))
(fn make-setter [prop]
  (fn [widget value]
      (let [f (. widget (.. :set_ prop))]
        (f widget value))))
(fn vargs [prop]
  (fn [widget value]
    (let [f (. widget (.. :set_ prop))]
      (f widget (table.unpack value)))))

{
 : is-widget
 :label (make-builder gtk.label { :text (make-setter :label)
                                  :markup (make-setter :markup)})
 :button (make-builder gtk.button)
 :menu-button (make-builder gtk.menu_button)
 :image (make-builder gtk.image {:size (vargs :size)})
 :entry (make-builder gtk.text_box {:auto-focus (fn [w auto-focus]
                                                  (if auto-focus
                                                    (w:grab_focus)))})
 :check-button (make-builder gtk.check_button)
 :box (make-builder gtk.box)
 :list-box (make-builder gtk.list_box)
 :list-row (make-builder gtk.list_box_row)
 :flow-box (make-builder gtk.flow_box)
 :window (make-builder gtk.win {:default_size (fn [w [width height]]
                                                (w:set_default_size width height))
                                :pos (fn [w [x y]]
                                       (w:set_pos x y))
                                :size_request (fn [w [width height]]
                                                (w:set_size_request width height))})
 :scrolled-window (make-builder gtk.scrolled_win)
 :grid (make-builder gtk.grid)
 ;:notebook (make-builder gtk.note_book)
 :event-box (make-builder gtk.event_box)}
 ; :popover (make-builder gtk.popover {:visible (fn [w visible]
 ;                                                (if visible 
 ;                                                    (w:popup)
 ;                                                    (w:popdown)))})}
