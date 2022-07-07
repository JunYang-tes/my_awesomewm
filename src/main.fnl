(local root _G.root)                                    
(local gears (require :gears))                  
(local awful (require :awful))        
(local inspect (require :inspect))                       
(local modkey "Mod4")
(local tag (require :tag))
(require :rules)

(fn setup-global-keys []
  (local ks (require :key-bindings))
  (root.keys ks))

;; TODO
;; move focus
;; search key              
(setup-global-keys)
(tag.create) 
