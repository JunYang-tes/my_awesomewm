(local awful (require :awful))
(local wibox (require :wibox)) 
(local { : range : zip } (require :utils.list))                         
(local inspect (require :inspect))
(local { : on-idle } (require :utils.wm))
(local { : select-win } (require :windows.select-win))
(local { : focus } (require :utils.wm))            
(local screen-utils (require :utils.screen))

(fn normalize []
  (var flag false)
  (each [_ c (ipairs (. (awful.screen.focused) :clients))] 
    (if (or c.fullscreen c.maximized c.maximized_vertical c.maximized_horizontal) 
      (do
        (set flag true)
        (set c.fullscreen false) 
        (set c.maximized false) 
        (set c.maximized_vertical false) 
        (set c.maximized_horizontal false)))) 
  flag) 

(fn launch [make-it-fullscreen]
  (local clients (screen-utils.clients));(. (awful.screen.focused ) :clients)) 
  (fn handle-selected [{: client}] 
    (focus client) 
    (if make-it-fullscreen 
      (set client.fullscreen true)))
  (match (length clients) 
      1 (tset (. clients 1) :fullscreen (not (. clients 1 :fullscreen))) 
      _ (if (normalize) 
            (on-idle (fn [] (select-win {
                                         : clients
                                         :ignore-focus (not make-it-fullscreen)
                                         :on-selected handle-selected})))
                                        
            (select-win {
                         : clients
                         :on-selected handle-selected})))) 
                          

{ : launch}
