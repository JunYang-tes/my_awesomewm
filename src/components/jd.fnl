(local awful (require :awful))
(local {: widget } (require :ui.builder))
(local screen-utils (require :utils.screen))
(local { : assign! } (require :utils.table))                    
(local width 1589)
(local height 315) 
(local inspect (require :inspect))

(local jd-keymap (awful.popup 
                  {
                   :widget 
                     (widget.image-box 
                       {
                        :image (.. (os.getenv "HOME")
                                   "/.config/awesome/src/components/jd.png") 
                        :forced_width width 
                        :forced_height height}) 
                   :ontop true 
                   :visible false})) 

(fn toggle-visible []
  (assign! jd-keymap (screen-utils.center
                       (awful.screen.focused) 
                       width height)) 
  (set jd-keymap.visible (not jd-keymap.visible))) 
                                              
{ : toggle-visible}
