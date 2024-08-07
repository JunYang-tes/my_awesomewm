(import-macros {: catch } :utils)
(local gtk (require :libgtk-lua))
(local {: apply-property
        : is-observable} (require :lite-reactive.observable))
(local strings (require :utils.string))
(local list (require :utils.list))
(local utils (require :utils.utils))
(local inspect (require :inspect))
(local {: assign} (require :utils.table))

(fn make-builder [Ctor props-setter ctor-has-param]
  (local props-setter (or props-setter {}))
  (tset props-setter :class
        (fn [w cls old]
          (when old
            (each [_ v (ipairs (strings.split old " "))]
              (if (not= v "")
                (w:remove_css_class v))))
          (each [_ v (ipairs (strings.split cls " "))]
            (if (not= v "")
              (w:add_css_class v)))))
  (tset props-setter :size_request
        (fn [w size]
          (w:set_size_request (table.unpack size))))
  (fn find-setter [prop]
    (let [setter (. props-setter prop)]
      (when (= setter nil)
        (tset props-setter
              prop
              (fn [widget value]
                ; (catch (.. "Failed to set " prop " to " (tostring value) 
                ;            " of "
                ;            (tostring widget)
                ;            ":") 
                ;   nil)
                (let [f (or (. widget (.. :set_ prop))
                            ;connect_xx
                            (. widget prop))]
                  (if f
                    (f widget value)
                    (print "No " prop " or " (.. "set_"prop)))))))
      (. props-setter prop)))
  (fn [props]
    (let [
          ; props (assign {:visible true}
          ;               (or props {}))
          widget (if ctor-has-param
                   (Ctor props)
                   (Ctor))

          disposeable (icollect [k v (pairs props)]
                        (when (and 
                                (not= k :id)
                                (not= v nil))
                          (apply-property
                            v
                            (fn [value old]
                             ((find-setter k) widget value old)))))]
                            ; (utils.catch (fn [value old]
                            ;               ((find-setter k) widget value old))))))]
      widget)))
(fn make-setter [prop def]
  (fn [widget value]
      (let [f (. widget (.. :set_ prop))]
        (f widget (or value def)))))
(fn vargs [prop]
  (fn [widget value]
    (let [f (. widget (.. :set_ prop))]
      (f widget (table.unpack value)))))
(fn nilabel [prop]
  (fn [widget value]
    (let [f (. widget (.. :set_ prop))]
      (when (not= nil value)
        (f widget value)))))

{
 :label (make-builder gtk.label { :text (make-setter :label "")
                                  :label (make-setter :label "")
                                  :markup (make-setter :markup "")})
 :button (make-builder gtk.button)
 :overlay (make-builder gtk.overlay)
 :icon-button (make-builder (fn [props]
                              (let [name props.name]
                                (gtk.icon_button
                                  (if (is-observable name)
                                    (name)
                                    name))))
                            {:name (fn [w v]
                                     (w:set_icon_name v))}
                            true)
                                  
 ;:menu-button (make-builder gtk.menu_button)
 ;:image (make-builder gtk.image {:size (vargs :size)})
 :picture (make-builder gtk.picture {:size (vargs :size)
                                     :texture (nilabel :texture)
                                     :size_request (vargs :size_request)})
 :entry (make-builder gtk.text_box {:auto-focus (fn [w auto-focus]
                                                  (if auto-focus
                                                    (w:grab_focus)))})
 ;:check-button (make-builder gtk.check_button)
 :box (make-builder gtk.box)
 ;:list-box (make-builder gtk.list_box)
 ;:list-row (make-builder gtk.list_box_row)
 ;:flow-box (make-builder gtk.flow_box)
 :window (make-builder #(let [win (gtk.win)]
                          (win:present)
                          win)
                       {:default_size (fn [w [width height]]
                                       (w:set_default_size width height))
                        :pos (fn [w [x y]]
                               (w:set_pos x y))
                        :size_request (fn [w [width height]]
                                        (w:set_size_request width height))})
 :scrolled-window (make-builder gtk.scrolled_win)
 :list-view (make-builder gtk.list_view)
 :fixed (make-builder gtk.fixed)}
 ;:grid (make-builder gtk.grid)
 ;:notebook (make-builder gtk.note_book)
 ;:event-box (make-builder gtk.event_box)}
 ; :popover (make-builder gtk.popover {:visible (fn [w visible]
 ;                                                (if visible 
 ;                                                    (w:popup)
 ;                                                    (w:popdown)))})}
