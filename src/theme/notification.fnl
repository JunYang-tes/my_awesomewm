(import-macros {: assign } :assign)
(local naughty (require :naughty))
(local menubar (require :menubar)) 

(set naughty.persistence_enabled true)
(set naughty.config.defaults.ontop true)                                     
(set naughty.config.defaults.timeout 6)                                       
(set naughty.config.defaults.title "System Notification")
(set naughty.config.defaults.position "top_right")
   
(if naughty.connect_signal
  (naughty.connect_signal "request::icon"
    (fn [n ctx hints] 
      (fn set-app-icon! []
        (local path (or 
                      (memubar.utils.lookup_icon hints.app_icon) 
                      (memubar.utils.lookup_icon (string.lower hints.app_icon)))) 
        (print :path path)
        (if path 
            (set n.icon path))) 
      (match ctx 
        :app_icon (set-app-icon!))))) 
