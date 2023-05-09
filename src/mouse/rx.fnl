(import-macros {: infix } :exp)
(local awful (require :awful))
(local Rx (require :rx))
(local utils (require :utils.utils))
(local {: assign } (require :utils.table))
(local {: panel-selector
        : position-motion
        : copy-mat} (require :mouse.utils))
(local mouse-input (require :utils.mouse))
(local inspect (require :inspect))

(fn keyboard-events []
  (local observers {})
  (awful.keygrabber
    {:autostart true
     :stop_key :Escape
     :stop_callback (fn []
                      (each [_ observer (ipairs observers)]
                        (observer:onCompleted )))
     :keypressed_callback (fn [a mod key]
                            (let [key (match key
                                        :bracketleft "["
                                        :bracketright "]"
                                        _ key)]
                              (each [_ observer (ipairs observers)]
                                (observer:onNext 
                                  {: key }))))})
  (Rx.Observable.create (fn [observer]
                          (table.insert observers observer))))

(fn parse-cmd [stream]
  (-> stream
      (: :filter (fn [event] (= 1 (length event.key))))
      (: :scan (fn [acc event]
                  (let [key event.key]
                    (if (= acc.keys "")
                      (if (utils.is-digital key)
                        (assign acc {:keys key :result nil})
                        (assign acc {:keys "" :result { : key
                                                        :count nil }}))
                      (utils.is-digital key) (assign acc {:keys (.. acc.keys key)})
                      (assign acc {:keys "" :result { : key
                                                      :count  (tonumber acc.keys) }}))))
         {:keys "" :result nil})
      (: :filter (fn [data] (not= data.result nil)))
      (: :map (fn [data] data.result))))

(fn move-panel [raw-events]
  (-> raw-events
      (: :filter (fn [event] (. panel-selector event.key)))
      (: :map (fn [event]
                (let [update (. panel-selector event.key)]
                  (fn [state]
                    (let [coords state.coords
                          mat (update coords.transform
                                      coords.geometry.width
                                      coords.geometry.height)
                          invert (let [invert (copy-mat coords.transform)]
                                   (invert:invert)
                                   invert)
                          (original-x original-y) (invert:transform_point
                                                    coords.position.x
                                                    coords.position.y)
                          (nx ny) (mat:transform_point original-x original-y)]
                      (state.history.undo.push coords)
                      (assign state
                              {:coords
                               (assign coords
                                       {:transform mat
                                        :position (assign
                                                    state.position
                                                    {:x nx
                                                     :y ny})})}))))))))
(fn move-to-panel-center [raw-events]
  (-> raw-events
      (: :filter #(or (= $1.key "Q")
                      (= $1.key "W")
                      (= $1.key "E")
                      (= $1.key "A")
                      (= $1.key "S")
                      (= $1.key "D")
                      (= $1.key "Z")
                      (= $1.key "X")
                      (= $1.key "C")))
      (: :map (fn [data]
                (fn [state]
                  (let [(x y) (state.coords.transform:transform_point 0 0)
                        (x1 y1) (state.coords.transform:transform_point
                                 state.coords.geometry.width
                                 state.coords.geometry.height)
                        width (infix (x1 - x) / 3)
                        height (infix (y1 - y) / 3)
                        half-width (infix width / 2)
                        half-height (infix height / 2)
                        coords state.coords
                        new-coords (match data.key
                                     :Q (assign coords
                                                {:position (assign coords.position
                                                                      {:x (infix x + half-width)
                                                                       :y (infix y + half-height)})})
                                     :W (assign coords
                                                {:position (assign coords.position
                                                                      {:x (infix x + width + half-width)
                                                                       :y (infix y + half-height)})})
                                     :E (assign coords
                                                {:position (assign coords.position
                                                                      {:x (infix x1 - half-width)
                                                                       :y (infix y + half-height)})})
                                     :A (assign coords
                                                {:position (assign coords.position
                                                                      {:x (infix x + half-width)
                                                                       :y (infix y + height + half-height)})})
                                     :S (assign coords
                                                {:position (assign coords.position
                                                                      {:x (infix x + width + half-width)
                                                                       :y (infix y + height + half-height)})})
                                     :D (assign coords
                                                {:position (assign coords.position
                                                                      {:x (infix x1 - half-width)
                                                                       :y (infix y + height + half-height)})})
                                     :Z (assign coords
                                                {:position (assign coords.position
                                                                      {:x (infix x + half-width)
                                                                       :y (infix y1 - half-height)})})
                                     :X (assign coords
                                                {:position (assign coords.position
                                                                      {:x (infix x + width + half-width)
                                                                       :y (infix y1 - half-height)})})
                                     :C (assign coords
                                                {:position (assign coords.position
                                                                      {:x (infix x1 -  half-width)
                                                                       :y (infix y1 - half-height)})}))]
                    (assign state {:coords new-coords})))))))
(fn click [raw-events]
  (-> raw-events
      (: :filter #(or (= $1.key ",")
                      (= $1.key ".")))
      (: :map (fn [data]
                (fn [state]
                  (table.insert state.effects
                                (fn [state]
                                    (match data.key
                                      "," (mouse-input.left-click
                                            state.coords.position.x
                                            state.coords.position.y)
                                      "." (mouse-input.right-click
                                            state.coords.position.x
                                            state.coords.position.y))))
                  (assign state
                          {:mouse-left :none}))))))

(fn history [raw-events]
  (-> raw-events
      (: :filter #(or (= $1.key "u")
                      (= $1.key "r")))
      (: :map (fn [data]
                (fn [state]
                  (match data.key
                    "u" (let [coords ( state.history.undo.pop) ]
                          (print :undo (inspect coords))
                          (if coords
                            (state.history.redo.push coords))
                          (if coords
                            (assign state
                                    {:coords coords})
                            state))
                    "r" (let [coords ( state.history.redo.pop) ]
                          (if coords
                            (state.history.undo.push coords))
                          (if coords
                            (assign state
                                    {:coords coords})
                            state))
                    _ state))))))
(fn move-position [raw-events]
  (-> raw-events
      (: :filter #(. position-motion (string.lower $1.key)))
      (: :map (fn [data]
                (fn [state]
                  (let [update (. position-motion (string.lower data.key))
                        count (if (utils.is-uppercase data.key)
                                50
                                10)]
                    (assign state
                            {:coords
                             (assign state.coords
                                     {:position (update (or data.count 
                                                            count)
                                                        state.coords.position)})})))))))
(fn wheel [raw-events]
  (-> raw-events
      (: :filter #(or (= $1.key "[")
                      (= $1.key "]")))
      (: :map (fn [data]
                (fn [state]
                  (print data.key)
                  (let [wheel-effect (if (= data.key "[")
                                        mouse-input.wheel-up
                                        mouse-input.wheel-down)]
                    (table.insert state.effects
                                  (fn []
                                    (print state.coords.position.x
                                           state.coords.position.y)
                                    (wheel-effect state.coords.position.x
                                                  state.coords.position.y)))
                    state))))))

(fn mouse-left [raw-events]
  (-> raw-events
      (: :filter #(= $1.key "<"))
      (: :map (fn [data]
                (fn [state]
                  (assign state
                          {:mouse-left (match state.mouse-left
                                          :none :down
                                          :down :up
                                          :up :none)}))))))
{: parse-cmd
 : keyboard-events
 : move-panel
 : move-to-panel-center
 : move-position
 : history
 : mouse-left
 : wheel
 : click}
