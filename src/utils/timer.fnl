(local gears (require :gears))
(fn set-timeout [f time]
  (local t (gears.timer {
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
