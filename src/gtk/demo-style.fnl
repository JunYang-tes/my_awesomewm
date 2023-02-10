(import-macros {: css-gen} :css)
(import-macros {: css} :gtk)
(import-macros {: unmount : defn } :lite-reactive)
(local {: run } (require :lite-reactive.app))
(local {: Gtk : Gdk } (require :lgi))
(local {: window
        : box
        : entry
        : label
        : button} (require :gtk.node))
(defn
  app
  (window 
    {
     :title :style}
     ;:class (css (& "*" [:border "10px solid pink"]))}
    (box
      (label { 
              :text :Label
              :class (css 
                       [:color :red
                        :border "10px solid black"
                        :font-size :20px])})
      (button {:class (css [:background :red
                            :border-radius :20px
                            :font-size :40px] 
                        (& ::hover
                           [:color :white
                            :background :green]))
               :label :Hello})
      (entry {:class (css [:font-size :30px
                           :color :red])})
      (button {
               :label :World}))))
(run (app))

;; (local style (require :gtk.style))
;; (local btn
;;        (button {:label :Button :vexpand false}))

;; (local provider (Gtk.CssProvider))
;; (provider:load_from_data ".red { background-color:red; } ")
;; ;; (print :load
;; ;;   (provider:load_from_data """
;; ;;                            window {
;; ;;                             background-color: green;
;; ;;                            }
;; ;;                            """))
;; ;; (provider:load_from_path :style.css)
;; (Gtk.StyleContext.add_provider_for_screen
;;   (Gdk.Screen.get_default)
;;   provider
;;   Gtk.STYLE_PROVIDER_PRIORITY_USER)

;; (local win
;;   (window
;;     btn))

;; (local ctx (win:get_style_context))
;; (ctx:add_class :red)

