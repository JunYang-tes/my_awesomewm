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
(local {: window
        : entry} (require :gtk.node))
(local {: value } (require :lite-reactive.observable))
(local {: Gdk } (require :lgi))
(local {: is-enter-event } (require :gtk.utils))
(local keys (require :gtk.keyval))
 
(local entry-style 
       (global-css 
         [:font-size :30px]))
(local win-style
       (global-css
         [:min-width :500px
          :max-width :500px]))
(defn prompt-node
  (let [
        {: on-finished
         : visible} props
        close (fn [win-node]
                (print :close)
                (visible false))
        win
        (window
          {
           :keep-alive true
           : visible
           :role :prompt
           ;; :default_width 500
           ;; :default_height 30
           :on_focus_out_event #(close win)}
          (entry
            { 
              :class entry-style
              ;; :auto-focus true
              :on_parent_set (fn [w] 
                                 (w:grab_focus))
              :on_key_release_event 
              (fn [w e]
                (catch-ignore ""
                  (match e.keyval
                    keys.esc (close win)
                    keys.enter (do
                                 ((on-finished) w.text)
                                 (close win)))))}))]
    win))
(local prompt-win
  (let [visible (value false)
        on-finished (value #$)]
    (run (prompt-node
           {: on-finished
            : visible}))
    {:show (fn [{:on-finished on-finished-callback}]
            (if (visible)
                (visible false)
                (do
                  (on-finished on-finished-callback)
                  (visible true))))}))

(fn prompt [{: on-finished}]
  (prompt-win.show {: on-finished}))
{ : prompt}
