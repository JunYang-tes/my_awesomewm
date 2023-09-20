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
(local wibar
  (container-node
    (make-builder (fn [props]
                    (print (inspect props))
                    (awful.wibar
                      {:widget (wibox.widget {:text ""
                                              :widget wibox.widget.textbox})
                       :height props.height
                       :position :bottom})))
    (fn [child p]
      (tset p :widget (. child 1)))))

(local events
  (event-props
    [
     [:onButtonPress "button::press"]
     [:onButtonRelease "button::release"]]))
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
