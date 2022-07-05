(local focus-win (require :focus-win))
(local root _G.root)                                    
(local gears (require :gears))                  
(local awful (require :awful))        
(local inspect (require :inspect))                       
(local modkey "Mod4")
(require :rules)

(fn setup-global-keys []
  (local ks (require :key-bindings))
  (root.keys ks))

;; TODO
;; Swap client
;; search key              
(setup-global-keys)
