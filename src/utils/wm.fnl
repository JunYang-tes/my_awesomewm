(local awful (require :awful))
(local awesome-global (require :awesome-global))
(local { : find 
         : filter
         : map 
         : max-by} 
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

(fn get-by-direct [item items dir geometry-accessor]
  (local geometry-accessor (or geometry-accessor 
                               #{:x $1.x :y $1.y :width $1.width :height $1.height})) 

  (local overlap-weight
    (match dir 
      "up" (fn [a b]
             ;; b is above a
             (if (>= a.y (+ b.y b.height))
               (do 
                 (local intersection-x (- (+ a.x a.width) b.x)) 
                 (math.abs intersection-x)) 
               -1)) 
              
      "down" (fn [a b]
               (if (<= (+ a.y a.height) b.y)
                   (do 
                     (local intersection-x (- (+ a.x a.width) b.x)) 
                     (math.abs intersection-x)) 
                   -1)) 
      "left" (fn [a b]
               (if (>= a.x (+ b.x b.width))
                 (do 
                   (local intersection-y (- (+ a.y a.height) b.y)) 
                   (math.abs intersection-y)) 
                 -1)) 
      "right" (fn [a b]
                (if (<= (+ a.x a.width) b.x)
                  (do 
                    (local intersection-y (- (+ a.y a.height) b.y)) 
                    (math.abs intersection-y)) 
                  -1)))) 
          
  (local checked
    (-> items 
      (map (fn [i] 
             (if (= i item) 
                 [0 i] 
                 [(overlap-weight (geometry-accessor item) (geometry-accessor i)) i]))) 
      (filter (fn [[weight]] (> weight 0)))))
  (if (> (length checked) 0) 
      (. (max-by checked #(. $1 1)) 2) 
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
