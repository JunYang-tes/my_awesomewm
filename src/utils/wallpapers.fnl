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
(local widgets (require :widgets))

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

(fn set-wallpaper-for-tag [tag]
  (let [ind (+ 1 (% tag.index
                    (length wallpapers)))
        wp (or
             (. tag :_tag_wallpaper) 
             (. wallpapers ind))]

    (gears.wallpaper.maximized
      wp tag.screen)))


{ : get-random
  : set-wallpaper-for-tag}
