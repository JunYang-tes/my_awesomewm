(local gears (require :gears))
(fn set-timeout [f time]
  (var t nil)
  (set t (gears.timer {
                         :timeout time
                         :autostart true
                         :callback (fn [] 
                                     (t:stop) 
                                     (f))}))
  t) 
(fn clear-timeout [timer]
  (timer:stop)) 
{ : set-timeout
  : clear-timeout} 
