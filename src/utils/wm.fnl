(local awful (require :awful))
(local awesome-global (require :awesome-global))
(local { : find 
         : filter
         : map 
         : min-by} 
       (require :utils.list)) 
(local inspect (require :inspect)) 
 
(local xresources (require :beautiful.xresources))                                                    
(local dpi xresources.apply_dpi) 

(fn on-idle [f]
  (fn on-refresh [] 
    (pcall f) 
    (awesome-global.awesome.disconnect_signal :refresh on-refresh)) 
  (awesome-global.awesome.connect_signal :refresh on-refresh)) 
      
(fn focus [client] 
  (if client
    (set awesome-global.client.focus client))) 

(fn get-focusable-client [tag]
  (if tag
    (or (find (tag:clients ) (fn [c] c.fullscreen)) 
        (. (tag:clients) 1)))) 

(fn get-by-direct [item items dir {: width : height} geometry-accessor]
  (local geometry-accessor (or geometry-accessor 
                               #{:x $1.x :y $1.y :width $1.width :height $1.height})) 

  (local overlap-weight
    (match dir 
      "up" (fn [a b]
             ;; b is above a
             (local y (- a.y (+ b.y b.height))) 
             (local x (math.abs (- a.x b.x))) 
             (+ (* 10 (/ y height)) 
                (/ x width))) 
              
      "down" (fn [a b]
               (local y (- b.y (+ a.y a.height))) 
               (local x (math.abs (- a.x b.x))) 
               (+ (* 10 (/ y height)) 
                  (/ x width))) 
      "left" (fn [a b]
               (local x (- a.x (+ b.x b.width))) 
               (local y (math.abs (- a.y b.y))) 
               (+ (* 10 (/ x width))
                  (/ y height))) 
      "right" (fn [a b]
               (local x (- b.x (+ a.x a.width))) 
               (local y (math.abs (- a.y b.y))) 
               (+ (* 10 (/ x width))
                  (/ y height))))) 
          
  (local checked
    (-> items 
      (map (fn [i] 
             (if (= i item) 
                 [(/ 1 0) i] 
                 [(overlap-weight (geometry-accessor item) (geometry-accessor i)) i]))) 
      (filter (fn [[i]] (> i 0))))) 
  (if (> (length checked) 0) 
      (. (min-by checked #(. $1 1)) 2) 
      item)) 

(fn get-current-tag []
  (local screen (awful.screen.focused)) 
  screen.selected_tag) 

{ : on-idle
  : focus 
  : get-focusable-client 
  : get-by-direct 
  : get-current-tag
  : dpi} 
