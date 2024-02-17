(local awful (require :awful))
(local lfs (require :lfs))
(local beautiful (require :beautiful))
(local inspect (require :inspect))
(local { : random } (require :utils.math))
(local gears (require :gears))
(local screen-utils (require :utils.screen))
(local surface (require :gears.surface))

(fn get-wallpapers []
  (fn do-get []
    (icollect [v (lfs.dir beautiful.wallpapers_path)]
       (if (and (not= v ".")
                (not= v "..")
                (not= v "images"))
           (.. beautiful.wallpapers_path "/" v))))
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
        (local wp (surface.load_silently (. wallpapers (random 1 (+ 1 (length wallpapers))))))
        (tset memoed key wp)
        wp)))

(fn set-wallpaper [tag]
  (gears.wallpaper.maximized
    (get-random tag)
    tag.screen))

(fn wp-each-screen []
  (local base (. (os.date :*t) :day))
  (fn set-wp [screen]
    (if (> (length wallpapers) 0)
      (gears.wallpaper.maximized
        (. wallpapers (+ 1 (% (+  screen.index base)
                              (length wallpapers))))
        screen)))
  (awful.screen.connect_for_each_screen
    (fn [screen]
      (set-wp screen)
      (screen:connect_signal "property::geometry" set-wp))))

{ : get-random
  : set-wallpaper
  : wp-each-screen}
