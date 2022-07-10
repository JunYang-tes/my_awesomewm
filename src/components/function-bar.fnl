(local awful (require :awful))
(local beautiful (require :beautiful))
(local {: container 
        : layout 
        : widget} (require :ui.builder)) 
(local wibox (require :wibox)) 
(local { : assign! } (require :utils.table))                    
(local ui (require :utils.ui)) 

(local bar-height 40)
(local bar-offset-y 30) 

(fn get-bar-geometry [] 
  (local screen (awful.screen.focused)) 
  (local { : width : height} screen.geometry)
  (print height)
  {
   :x 0
   :y (- height bar-height bar-offset-y) 
   :height bar-height
   :width width}) 
    

(local function-bar
  (awful.popup 
    (assign!
      {
        :widget (wibox.widget
                  (container.place
                    {
                     :forced_width (. (awful.screen.focused) :geometry :width)} 
                    (container.background
                      { 
                       :shape (ui.rrect 10)
                       :forced_height bar-height
                       :bg beautiful.wibar_bg}
                      (layout.fixed-horizontal
                        { :spacing 2}
                        (container.margin
                          {:left 10}
                          (widget.textbox {:markup ""}))
                        (widget.text-clock) 
                        (container.margin
                          {:top 8 :right 10}
                          (do 
                            (local systray (wibox.widget.systray)) 
                            (systray:set_base_size 20) 
                            systray)) 
                        (container.margin
                          {:right 10} 
                          (widget.textbox {:markup ""}))))))
        :border_width 0
        :bg :#fff00000
        :ontop true 
        :visible false} 
      (get-bar-geometry))))
                     

(fn toggle-visible []
  (local screen (awful.screen.focused)) 
  (assign! 
    function-bar 
    {:visible (not function-bar.visible)})) 
                 
{ : toggle-visible}
