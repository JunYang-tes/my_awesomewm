(local awful (require :awful))
(local beautiful (require :beautiful))
(local {: container 
        : layout 
        : widget} (require :ui.builder)) 
(local wibox (require :wibox)) 
(local { : assign! } (require :utils.table))                    
(local ui (require :utils.ui)) 
(local signal (require :utils.signal))                         

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

(fn tag-indicator []
  (local tag-name (wibox.widget 
                    (widget.textbox {:markup "T"}))) 
  (signal.connect-signal "tag::selected"
    (fn [tag] 
      (set tag-name.markup tag.name))) 
  (signal.connect-signal "tag::rename" 
    (fn [tag _ new-name] 
      (set tag-name.markup new-name))) 
  (layout.fixed-horizontal 
    {:spacing 2} 
    (container.background
      (widget.font-icon "sell"))  
    tag-name)) 

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
                      (container.margin
                        { :left 10 :right 10}
                        (layout.fixed-horizontal
                          { 
                            :spacing 16}
                          (tag-indicator)
                          (layout.fixed-horizontal
                            { :spacing 2}
                            (widget.font-icon "date_range")
                            (widget.text-clock)) 
                          (container.margin
                            {:top 8 :right 10}
                            (do 
                              (local systray (wibox.widget.systray)) 
                              (systray:set_base_size 20) 
                              systray))))))) 
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
