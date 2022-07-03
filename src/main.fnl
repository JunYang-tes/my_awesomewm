(print "run fennel config")
(local focus-win (require :focus-win))
(local root _G.root)                                    
(local gears (require :gears))                  
(local awful (require :awful))        
(local inspect (require :inspect))                       
(local modkey "Mod4")

(fn setup-global-keys []
  (local keys (root.keys)) 
  (print (inspect keys)) 
  (-> keys                         
      (gears.table.join 
        (awful.key [modkey] "f" (fn [] (focus-win.launch true)))) 
      (root.keys))) 


(setup-global-keys)
