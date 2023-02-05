(local jd-map (require :components.jd))
(local awful (require :awful))
(local date {:label :date
             :real-time (fn [] (os.date "%Y/%m/%d"))})
(local time {:label :time
             :real-time (fn [] (os.date "%X"))
             :exec #$})
(local calc {:label :calc
             :real-time (fn [input] ((load (.. "return " input))))})
(local screenshot
       {:label :screen-shot
        :exec #(awful.spawn "flameshot gui")})
(local jd
       (do 
         (var visible false)
         {:label :jd-map
          :real-time #(if visible "Close jd map" "Open jd map")
          :exec (fn []
                  (set visible (not visible))
                  (jd-map.toggle-visible))}))
(local color-picker
       {:label :color-picker
        :exec (fn []
                (awful.spawn "sh -c \"gcolor3 | xclip -sel clip\""))})
[date time calc screenshot jd color-picker]
