(local gears (require :gears))                  
(local theme (require :theme.theme))
(local beautiful (require :beautiful)) 
(beautiful.init theme)
(require :theme.notification) 

(local root _G.root)                                    
(local awful (require :awful))        
(local inspect (require :inspect))                       
(local modkey "Mod4")
(local tag (require :tag))
(local {: tag-untaged} (require :client))  
 
(require :notification)
(require :rules)
(require :components.function-bar) 
(require :autorun)

(fn setup-global-keys []
  (print :set-keys)
  (local ks (require :key-bindings))
  (print ks)
  (root.keys ks))

;; TODO
;; move focus
;; search key              
;; exit fullscreen when new window was opened 
(setup-global-keys)
(tag:init)
(tag-untaged) 
