(local lgi (require :lgi))
(local cairo lgi.cairo)
(local Rx (require :rx))
(local awful (require :awful))
(local {: make} (require :mouse.indicator))
(local {: keyboard-events
        : history
        : move-panel
        : move-to-panel-center
        : move-position
        : mouse-left
        : wheel
        : click } (require :mouse.rx))
(local {: wrap-mouse-fns-on-focused } (require :utils.screen))
(local mouse-input (wrap-mouse-fns-on-focused (require :utils.mouse)))
(local {: assign } (require :utils.table))
(local {: make-stack } (require :utils.stack))
(local inspect (require :inspect))

(fn create-state [geometry]
  {:coords {:transform (cairo.Matrix.create_identity)
            : geometry
            :position {:x (/ geometry.width 2)
                       :y (/ geometry.height 2)}}
   :mouse-left "none" ;"down" "up"
   :effects []
   :history {:undo (make-stack)
             :redo (make-stack)}})

(local states (let [states {}]
                {:get (fn []
                        (let [screen (awful.screen.focused)
                              tag screen.selected_tag
                              geometry screen.geometry
                              state (. states tag)]
                          (if state
                            state
                            (let [state (create-state geometry)]
                              (tset states tag state)
                              state))))
                 :set (fn [state]
                         (let [screen (awful.screen.focused)
                               tag screen.selected_tag]
                           (tset states tag state)))}))

(fn run []
  (let [screen (awful.screen.focused)
        geometry screen.geometry
        initial-state (states.get)
        indicator (make initial-state.coords.position.x
                        initial-state.coords.position.y
                        (- geometry.width 2) (- geometry.height 2)
                        2)
        on-error (fn [...]
                   (print :Error ...)
                   (indicator.close))
        on-completed (fn [] (indicator.close))
        raw-events (keyboard-events)]

    (fn apply-coords [state]
      (let [(x y) (state.coords.transform:transform_point 0 0)
                  (x2 y2) (state.coords.transform:transform_point
                            geometry.width geometry.height)]
           (mouse-input.move-to state.coords.position.x
                                state.coords.position.y)
           (indicator.update {: x
                              : y
                              :width (- x2 x)
                              :height (- y2 y)}
                             state.coords.position)))
    (apply-coords initial-state)
    (-> (Rx.Observable.empty)
      (: :merge
         (move-panel raw-events)
         (move-position raw-events)
         (move-to-panel-center raw-events)
         (history raw-events)
         (mouse-left raw-events)
         (wheel raw-events)
         (click raw-events))
      (: :scan (fn [state update]
                 (update state))
         initial-state)
      (: :tap (fn [state]
                (apply-coords state)
                (match state.mouse-left
                  :down (mouse-input.press-left state.coords.position.x
                                                state.coords.position.y)
                  :up (mouse-input.release-left state.coords.position.x
                                                state.coords.position.y))
                (each [_ f (ipairs state.effects)]
                  (f state))
                (tset state :effects [])
                (states.set state)))
      (: :subscribe (fn []) on-error on-completed))))

{: run}
