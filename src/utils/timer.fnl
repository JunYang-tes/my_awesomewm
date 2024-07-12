(local gears (require :gears))
(fn set-timeout [f time]
  (var t nil)
  (set t (gears.timer {
                         :timeout time
                         :autostart true
                         :call_now false
                         :callback (fn [] 
                                     (t:stop)
                                     (tset t :__stopped true)
                                     (f))}))
  (tset t :__stopped false)
  t) 
(fn clear-timeout [timer]
  (when (not timer.__stopped)
    (timer:stop))) 

(fn debounce [f timeout]
  (var id nil)
  (fn [...]
    (if (not= id nil)
      (clear-timeout id))
    (let [args [...]]
      (set
        id
         (set-timeout
           #(f (table.unpack args))
           (/ timeout 1000))))))

{ : set-timeout
  : debounce
  : clear-timeout} 
