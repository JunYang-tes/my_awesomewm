(local gears (require :gears))                  
(local beautiful (require :beautiful)) 
(beautiful.init (.. (gears.filesystem.get_themes_dir ) "zenburn/theme.lua"))

(local root _G.root)                                    
(local awful (require :awful))        
(local inspect (require :inspect))                       
(local modkey "Mod4")
(local tag (require :tag))
 
(require :rules)

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
