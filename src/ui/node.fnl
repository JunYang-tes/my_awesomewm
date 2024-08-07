(import-macros {: catch
                : time-it} :utils)
(local awful (require :awful))
(local wibox (require :wibox))
(local { : dpi : on-idle} (require :utils.wm))
(local gears (require :gears))
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
(local scrollview (require :ui.scrollview))
(local dndoverlay (require :libxdnd-overlay))
(local wm (require :utils.wm))

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
      (when curr
        (widget:disconnect_signal event-name curr))
      (if (= event-name :onSystrayUpdate)
        (print :connect-onSystrayUpdate))
      (widget:connect_signal event-name cb))))
(local events
  (event-props
    [
     [:onButtonPress "button::press"]
     [:onMouseEnter "mouse::enter"]
     [:onMouseLeave "mouse::leave"]
     [:onLayoutChanged "widget::layout_changed"]
     [:onButtonRelease "button::release"]]))

(local popup
  (container-node
    (make-builder (fn [props]
                    (awful.popup 
                      (assign props
                        {:widget (wibox.widget {:text ""
                                                :widget wibox.widget.textbox})
                         :ontop (if (= nil props.ontop)
                                  props.ontop true)
                         :visible (if (= nil props.visible)
                                    props.visible true)})))
                  events)
    (fn [child popup]
      (tset popup :widget (. child 1)))))
(local wibar
  (container-node
    (make-builder (fn [props]
                    (let [bar
                          (awful.wibar
                            (assign 
                              props
                              {:widget (wibox.widget {:text ""
                                                      :widget wibox.widget.textbox})}))
                          has_overlay (if (is-observable props.fire-motion-on-dnd)
                                         (props.fire-motion-on-dnd)
                                         (or props.fire-motion-on-dnd false))]
                      (when has_overlay
                        (bar:connect_signal
                          "property::visible"
                          (fn []
                            (if (and bar.visible)
                              (do (print :show)
                                  (dndoverlay.show bar.drawin.window))
                              (do (print :hide)
                                  (dndoverlay.hide bar.drawin.window))))))
                      (when has_overlay
                        (wm.on-idle #(dndoverlay.make_a_overlay bar.drawin.window)))
                      bar)))
    (fn [child p]
      (tset p :widget (. child 1)))))

(local textbox
  (atom-node
    (make-builder (fn [props]
                     (wibox.widget.textbox props.markup))
                  events)
    :textbox))

(fn one-child-container [Ctor props-setter]
  (container-node
    (make-builder #(Ctor) props-setter)
    (fn [child container]
      (if container.set_child
        (container:set_child (. child 1)))
      (tset container :widget (. child 1)))))

{: popup
 : textbox
 : wibar
 : events
 : event-props
 : make-builder
 :textclock (atom-node
              (make-builder #(wibox.widget.textclock)))
 :factory {: one-child-container}
 :imagebox (atom-node
             (make-builder
               #(wibox.widget
                  {:widget wibox.widget.imagebox})))
 :client-icon (atom-node
                (make-builder
                  #(awful.widget.clienticon (. $1 :client))))
 :checkbox (atom-node
             (make-builder #(wibox.widget
                              {:widget wibox.widget.checkbox
                               :forced_width (dpi 30)
                               :forced_height (dpi 30)
                               :shape gears.shape.circle})))
 :button (atom-node
           (make-builder #(awful.widget.button)
                         events))
 :systray (atom-node
            (make-builder #(wibox.widget.systray)))
 :progress-bar (atom-node
                 (make-builder #(wibox.widget
                                  {:widget
                                    wibox.widget.progressbar
                                   :forced_height (dpi 20)
                                   :forced_width (dpi 100)})))
 :slider (atom-node
           (make-builder
             #(wibox.widget
                {:widget wibox.widget.slider
                 :bar_height (dpi 3)
                 :handle_width (dpi 16)
                 :handle_shape gears.shape.circle})
             (event-props
               [[:onValueChange :property::value]]))
           :slider)
 :background (one-child-container wibox.container.background)
 :margin (one-child-container wibox.container.margin)
 :h-flex (container-node
           (make-builder #(wibox.layout.flex.horizontal))
           (fn [children container]
             (tset container :children children)))
 :place (one-child-container wibox.container.place)
 :constraint (one-child-container wibox.container.constraint)
 :rotate (one-child-container wibox.container.rotate)
 :h-align (container-node
           (make-builder #(wibox.layout.align.horizontal))
           (fn [children container]
             (tset container :children children)))
 :v-align (container-node
           (make-builder #(wibox.layout.align.vertical))
           (fn [children container]
             (tset container :children children)))
 :v-flex (container-node
           (make-builder #(wibox.layout.flex.vertical))
           (fn [children container]
             (tset container :children children)))
 :h-fixed (container-node
            (make-builder #(wibox.layout.fixed.horizontal) events)
            (fn [children container]
              (tset container :children children)))
 :v-fixed (container-node
            (make-builder #(wibox.layout.fixed.vertical))
            (fn [children container]
              (tset container :children children)))
 :scrollview (one-child-container scrollview)
 :stack (container-node
          (make-builder #(wibox.layout.stack))
          (fn [children container]
            (tset container :children children)))}
