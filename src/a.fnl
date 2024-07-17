(import-macros {: time-it} :utils)
(local widget (require :widgets))
(local surface (require :gears.surface))
(local profile (require :ProFi))
(local wp (require :gears.wallpaper))

(profile:start)
(var surf nil)
; (time-it
;   :load-surf
;   (set surf
;     (surface.load_uncached
;       "/home/yj/.config/my_awesomewm/lua/theme/wallpapers/1.jpg")))
(time-it
  :load-surf1
  (set surf
       ;(widget.cairo.from_file "/home/yj/.config/my_awesomewm/lua/theme/wallpapers/2.jpg")
       (widget.cairo.from_file "/home/yj/.config/my_awesomewm/2.png")))
(time-it
  :set-wp
  (wp.maximized
    surf))
  
;   
(profile:stop)
(profile:writeReport "/tmp/a.txt")
