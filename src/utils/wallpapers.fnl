(local lfs (require :lfs)) 
(local beautiful (require :beautiful))
(local inspect (require :inspect)) 
(local { : random } (require :utils.math)) 
(local gears (require :gears)) 

(print :wallpapers-path beautiful.wallpapers_path)
(fn get-wallpapers []
  (fn do-get [] 
    (icollect [v (lfs.dir beautiful.wallpapers_path)] 
       (if (and (not= v ".") 
                (not= v "..")) 
           (.. beautiful.wallpapers_path "/" v)))) 
  (let [ (ok ret) (pcall do-get)] 
    (if ok 
        ret 
        (do 
          (print ret) 
          [])))) 


(local wallpapers (get-wallpapers)) 

(local memoed {})

(fn get-random [key]
  (local wp (. memoed key)) 
  (if wp 
      wp 
      (do
        (local wp (. wallpapers (random 1 (+ 1 (length wallpapers))))) 
        (tset memoed key wp) 
        wp))) 
         

(fn auto-switch []
  (gears.timer
    { :timeout (* 30 60) 
      :call_now true
      :callback (fn [] 
                  (print :switch-wallpaper)
                  (local wp (. wallpapers (random 1 (+ 1 (length wallpapers))))) 
                  (gears.wallpaper.maximized wp))})) 
        
{ : get-random
  : auto-switch} 
