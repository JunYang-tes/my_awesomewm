(local inspect (require :inspect))
(fn on-drag [widget  opt]
  (let [trigger_btn (or (?. opt :trigger_btn) 1)
        on-start (or opt.on-start (fn []))
        on-dragging (or opt.on-dragging (fn []))
        state {:handler on-start}
        handler (fn [...]
                  (state.handler ...)
                  (if (= state.handler on-start)
                    (tset state :handler on-dragging)))
        stop-drag (fn [drawable]
                    (tset state :handler on-start)
                    (drawable:disconnect_signal
                      :mouse::move handler))]
        
    (widget:weak_connect_signal
      :button::press
      (fn [_ x y btn mod {: drawable}]
        (when (= btn trigger_btn)
          (drawable:weak_connect_signal
            :mouse::move handler))))
    (widget:weak_connect_signal
      :mouse::leave
      (fn [_ {: drawable}]
        (stop-drag drawable)))
    (widget:weak_connect_signal
      :button::release
      (fn [_ x y btn mod {: drawable}]
        (stop-drag drawable)))))

{: on-drag}
