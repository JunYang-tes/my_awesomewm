(local awful (require :awful))
(local wibox (require :wibox))
(local inspect (require :inspect))
(local { 
        : range 
        : map 
        : filter 
        : some} 
  (require :utils.list))
(local gears (require :gears)) 
(local builder (require :ui.builder)) 
(local { : dpi : on-idle} (require :utils.wm))                   
(local beautiful (require :beautiful))
(local timer (require :utils.timer))                                   
(local naughty (require :naughty)) 

(fn read-popen [cmd]
 (with-open [in (io.popen cmd)]
  (icollect [i v (in:lines)] i)))

(fn read-prop [bat prop] 
  (with-open [in (io.open (.. "/sys/class/power_supply/" bat "/" prop))]
   (in:read)))
  ;(-> (io.open (.. "/sys/class/power_supply/" 
  ;                bat 
  ;                "/" 
  ;                prop 
  ;   (: :read)))) 
(fn read-num-prop [bat prop]                 
  (-> bat 
      (read-prop prop) 
      tonumber)) 
        

(fn is-battery [name] 
  (let [ lines (read-popen (..
                            "ls -1 "
                            "/sys/class/power_supply/" name))
         type (read-prop name :type)]
     
    (and 
      (= type :Battery)
      (some lines #(= $1 :charge_full)))))

(fn get-capacity [bat] 
  (fn get [] 
    (/ (tonumber (read-prop bat :charge_full)) 
       (tonumber (read-prop bat :charge_full_design)))) 
  (let [(ok data) (get)] 
    (if ok 
        data 
        1))) 

(fn calc-discharging-time [bat] 
  (local charge-full (read-num-prop bat :charge_full)) 
  (local charge-now (read-num-prop bat :charge_now)) 
  (local current-now (read-num-prop bat :current_now)) 
  (/ (- charge-full  charge-now) 
     current-now)) 

(fn calc-percentage [bat] 
  (math.min (/ (read-num-prop bat :charge_now) 
              (read-num-prop bat :charge_full)) 
            1)) 

(fn calc-charging-time [bat]
  0) 

(fn get-battery-info [bat]
  (fn []
    (fn go []
      (local charging? (= (read-prop bat :status)
                          :Charging)) 
      {
        :capacity (get-capacity bat)
        :percentage (calc-percentage bat)
        :name bat
        : charging? 
        ;; Charging/Discharging/Full
        :status (read-prop bat :status)
        :remaining-time (if charging? 
                            (calc-charging-time bat) 
                            (calc-discharging-time bat))}) 
    (let [(ok ret) (pcall go)] 
      (if ok 
          ret 
          (do
            (print "Faield to get batter info")
            (print bat)
            (print ret)
            {:capacity 0 
             :name bat
             :percentage 0 
             :charging? false 
             :status :Discharging
             :remaining-time 0}))))) 

(fn battery-count []
  (let [lines (read-popen "ls -1 /sys/class/power_supply")]
    (let [batteris (filter lines is-battery)]
      (length batteris)))) 

(fn discover []
  (let [lines (read-popen "ls -1 /sys/class/power_supply/")]
    (-> lines 
        (filter is-battery)
        (map get-battery-info)))) 

(local monitor 
  (do
    (local callbacks []) 
    (local batteris (discover)) 
    (fn emit []
      (local info (map batteris #($1))) 
      (each [_ f (ipairs callbacks)] 
        (pcall f info))) 
     
    (fn monitor []
      (fn start []
        (gears.timer 
          { :timeout 60 
            :call_now true 
            :autostart true
            :callback 
              (fn [] 
                (emit))})) 
      (if (> (length batteris) 0) 
          (start)))
                  
    (awful.spawn.with_line_callback
      "udevadm monitor -k --subsystem-match=power_supply " 
      {:stdout (fn [line] 
                  (timer.set-timeout emit 5))
       :stderr (fn [err] 
                 (print :err err))}) 

    (monitor)
    (fn add-callback [f] 
      (local info (map batteris #($1))) 
      (table.insert callbacks f) 
      (pcall f info)) 

    {: add-callback})) 

;;low power alert

(monitor.add-callback 
  (do 
    (var should-show-notify true)
    (fn [info]
      (each [i v (ipairs info)] 
        (if (= v.status :Charging)
            (set should-show-notify true)) 
        (if (and (= v.status :Discharging) 
                 (< v.percentage 0.15) 
                 should-show-notify) 
            (do 
              (naughty.notify 
                {
                 :preset naughty.config.presets.critical
                 :title (.. "Power low:" v.name)})
                         
              (set should-show-notify false)))))))                

(fn get-battery-color [info]
  (match info.status           
    "Discharging" (if (< info.percentage 0.1) :#960019 
                      (< info.percentage 0.2) :#FF7417 
                      beautiful.fg_normal) 
    _ beautiful.fg_normal))                   
 
(fn battery-indicator []
  (local {: layout  
          : container
          : widget} builder)
  (local tb (wibox.widget (widget.textbox {:markup ""}))) 
  (local bolt (wibox.widget
                (container.background
                  {:fg :#00ff00}
                  (widget.font-icon "bolt"
                    {:size 10 
                     :align :center})))) 
  (local battery-percentage (wibox.widget.base.make_widget))
  (set battery-percentage.fit (fn [] (values 10 24))) 
  (set battery-percentage.draw 
    (fn [widget ctx cr w h]
      (local x 0)
      (local y (- h
                  (* h 
                     (or widget.percentage 1)))) 
      (cr:set_line_width 0)
      (cr:set_source (gears.color (or widget.color beautiful.fg_normal))) 
      (cr:move_to x y) 
      (cr:line_to (+ x w) y) 
      (cr:line_to (+ x w) (+ y h)) 
      (cr:line_to  x  (+ y h)) 
      (cr:line_to  x  y) 
      (cr:fill)))
  (local icon
    (wibox.widget
      (layout.stack
        {:forced_height 40
         :forced_width 40} 
        (container.margin
          {:top 2}
          (container.place
            { :halign :center
              :valign :center} 
            battery-percentage)) 
        (container.background
          (widget.font-icon "battery_0_bar"  
            {:align :center})) 
        bolt))) 
  (local bt-widget 
    (layout.fixed-horizontal 
      {:spacing (dpi 1)} 
      icon
      tb))

  (fn update [info] 
    (set battery-percentage.percentage info.percentage)
    (set battery-percentage.color (get-battery-color info))
    (match info.status
      :Charging 
        (do
         (set bolt.visible true)) 
      :Full 
        (do
         (set bolt.visible true)) 
      :Discharging 
        (do 
          (set bolt.visible false))) 
    (if info.charging? 
      (set bolt.visible true) 
      (set bolt.visible false)) 
    (set tb.markup (.. (math.ceil (* 100 info.percentage)) 
                       "%"))) 
  { :widget bt-widget
    : update}) 

(fn widget []
  (local {: layout  
          : widget} builder)
  
  (local bs (-> (range 1 (+ (battery-count) 1) 1)
                (map battery-indicator))) 
             
  (monitor.add-callback 
    (fn [info]
      (each [i v (ipairs info)] 
        (do
          (local update (. bs i :update)) 
          (update v))))) 
  (wibox.widget
    (layout.fixed-horizontal 
      {:spacing (dpi 10)} 
      (table.unpack (map bs #$1.widget))))) 
            
{ : widget}
