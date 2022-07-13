(local awful (require :awful))
(local gears (require :gears))
(local wibox (require :wibox))
(local {: container 
        : layout 
        : widget} (require :ui.builder)) 
(local signal (require :utils.signal)) 

(fn get-volume []
  (-> 
    (io.popen "amixer sget Master") 
    (: :read "*a") 
    (string.match "(%d?%d?%d?)%%") 
    (tonumber))) 

(fn vol-widget []
  (local volume (get-volume))
  (local tb (wibox.widget (widget.textbox {:markup (tostring volume)})))
  (local slider (wibox.widget (widget.slider 
                                {
                                 :value volume
                                 :bar_height 3
                                 :handle_shape gears.shape.circle 
                                 :forced_width 100 
                                 :bar_width 100})))
                                 

  (local icon (widget.font-icon (if (> volume 0)
                                  "volume_up" 
                                  "volume_off"))) 
  (fn update-volume [] 
    (set tb.markup (tostring (get-volume)))) 

  (icon:connect_signal "button::release"
    (fn [] 
      (print :click))) 

  (slider:connect_signal "property::value"
    (fn [] 
      (local value slider.value) 
      (print value) 
      (awful.spawn (.."amixer set Master " value "%")) 
      (set tb.markup (tostring value)))) 
       
  (signal.connect-signal "volume::update"
    update-volume) 

  (layout.fixed-horizontal 
    {:spacing 2} 
    icon
    slider
    tb)) 

{
 : get-volume
 :widget vol-widget} 
 
