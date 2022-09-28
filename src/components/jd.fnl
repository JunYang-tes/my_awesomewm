(local awful (require :awful))
(local {: widget } (require :ui.builder))
(local screen-utils (require :utils.screen))
(local {: dpi} (require :utils.wm))          
(local { : assign! } (require :utils.table))                    
(local width 1589)
(local height 315)
(local inspect (require :inspect))
(local ratio (/ height width))

(var jd-keymap nil) 

(fn toggle-visible []
  (local screen (awful.screen.focused ))
  (local w screen.geometry.width)
  (local h (* ratio w))
  (print w h (/ w h))
  (if jd-keymap 
    (do
      (set jd-keymap.visible false)
      (set jd-keymap nil))
    (do
      (set jd-keymap
           (awful.popup 
                  {
                   :widget 
                     (widget.image-box 
                       {
                        :image (.. (os.getenv "HOME")
                                   "/.config/awesome/src/components/jd.png") 
                        :forced_width w 
                        :forced_height h}) 
                   :ontop true 
                   :visible true}))

        (assign! jd-keymap (screen-utils.center
                       (awful.screen.focused) 
                       w h)))))

{ : toggle-visible}
