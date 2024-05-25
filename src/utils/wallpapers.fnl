(local awful (require :awful))
(local {: fs } (require :widgets))
(local beautiful (require :beautiful))
(local inspect (require :inspect))
(local { : random } (require :utils.math))
(local gears (require :gears))
(local screen-utils (require :utils.screen))
(local surface (require :gears.surface))
(local stringx (require :utils.string))
(local {: spawn} (require :awful))

(fn get-wallpapers []
  (fn do-get []
    (icollect [_ v (ipairs (fs.dir beautiful.wallpapers_path))]
       (if (not (stringx.ends-with v :images)) 
           v)))
  (let [ (ok ret) (pcall do-get)]
    (if ok
        ret
        (do
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
(fn set-wallpaper [screen-idx path]
  (spawn (.. "hsetroot -screens " screen-idx
             " -fill "
             "'" path "'")))
             
  

(fn set-wallpaper-for-tag [tag]
  (let [ind (+ 1 (% tag.index
                    (length wallpapers)))
        wp (. wallpapers ind)]
    (set-wallpaper tag.screen.index wp)))



; (fn wp-each-screen []
;   (local base (. (os.date :*t) :day))
;   (fn set-wp [screen]
;     (if (> (length wallpapers) 0)
;       (gears.wallpaper.maximized
;         (. wallpapers (+ 1 (% (+  screen.index base)
;                               (length wallpapers))))
;         screen)))
;   (awful.screen.connect_for_each_screen
;     (fn [screen]
;       (set-wp screen)
;       (screen:connect_signal "property::geometry" set-wp))))

{ : get-random
  : set-wallpaper-for-tag}
  ;: wp-each-screen}
