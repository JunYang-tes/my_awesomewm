(import-macros {: unmount : defn } :lite-reactive)
(import-macros {: css-gen } :css)
(import-macros {: global-css} :gtk)
(import-macros {: catch-ignore} :utils)
(local awful (require :awful))
(local wibox (require :wibox)) 
(local beautiful (require :beautiful))
(local builder (require :ui.builder))
(local {: find} (require :utils.list))
(local {: dpi} (require :utils.wm))          
(local screen-utils (require :utils.screen)) 
(local {: run } (require :lite-reactive.app))
(local {: value } (require :lite-reactive.observable))
(local {: is-enter-event } (require :gtk.utils))
(local keys (require :gtk.keyval))
 
(local entry-style 
       (global-css 
         [:font-size :30px]))
(local win-style
       (global-css
         [:min-width :500px
          :max-width :500px]))

(fn prompt [{: on-finished}])
{ : prompt}
