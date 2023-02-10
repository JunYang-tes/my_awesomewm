(local awful (require :awful))
(local gears (require :gears))
(local wibox (require :wibox))
(local {: container 
        : layout 
        : widget} (require :ui.builder)) 
(local signal (require :utils.signal)) 
(local inspect (require :inspect))             
(local awesome-global (require :awesome-global))
(local { : dpi 
         : on-idle} 
  (require :utils.wm))                   
          

(fn read-popen [cmd]
 (with-open [in (io.popen cmd)]
   (in:read "*a")))

(fn get-volume []
  (or 
    (-> 
     (read-popen "amixer sget Master") 
     (string.match "(%d?%d?%d?)%%") 
     (tonumber)) 
    0)) 

(fn vol-widget []
  (local volume (get-volume))
  (local tb (wibox.widget (widget.textbox {:markup (tostring volume)})))
  (local slider (wibox.widget (widget.slider 
                                {
                                 :value volume
                                 :bar_height (dpi 3)
                                 :handle_width (dpi 16)
                                 :handle_shape gears.shape.circle}))) 
                                 ;; :forced_width 100 
                                 ;; :forced_height 30 
                                 ;; :bar_width 100})))
                                 

  (local icon (wibox.widget (widget.font-icon (if (> volume 0)
                                                "volume_up" 
                                                "volume_off")))) 
  (local slider-popup (awful.popup 
                        {
                         :widget 
                           (wibox.widget
                            (layout.fixed-vertical 
                               {:spacing 4
                                :forced_width 50}
                              (container.margin 
                                {:top 4} 
                                (container.rotate 
                                  {:direction :east
                                   :forced_height 100} 
                                  slider))
                              (container.margin 
                                {:bottom 4} 
                                (container.place 
                                  {:halign :center
                                   :valign :center} 
                                  icon)))) 
                         :ontop true 
                         :forced_width 100
                         :visible false})) 
     

  (fn update-volume [] 
    (local volume (get-volume))
    (set icon.markup (if (> volume 0)
                         "volume_up" 
                         "volume_off")) 
    (set tb.markup (tostring volume))) 

  (slider:connect_signal "property::value"
    (fn [] 
      (local value slider.value) 
      (awful.spawn (.."amixer set Master " value "%")) 
      (update-volume)))
       
  (signal.connect-signal "volume::update"
    update-volume) 
  (fn close-slider-popup []
    (set slider-popup.visible false)) 
  (awesome-global.client.connect_signal "button::press" close-slider-popup)
  (awesome-global.root.buttons
    (awful.util.table.join
      ;(awesome-global.root.buttons) 
      (awful.button {} 1 close-slider-popup)))

  (local w
    (wibox.widget
      (layout.fixed-horizontal 
        {:spacing 2} 
        icon
        tb))) 
  (icon:connect_signal "button::release"
    (fn [] 
      (set slider-popup.visible (not slider-popup.visible))
      (if slider-popup.visible
        (on-idle
          (fn []
            (local r (awful.placement.next_to slider-popup
                                            { :geometry _G.mouse.current_widget_geometry
                                              :preferred_anchors :middle 
                                              :preferred_positions :top}))))))) 
                                                      
  w) 

{
 : get-volume
 :widget vol-widget} 
 
