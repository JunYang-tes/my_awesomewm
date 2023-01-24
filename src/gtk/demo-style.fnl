(local {: Gtk : Gdk } (require :lgi))
(local {: window
        : button} (require :gtk.widgets))
(local style (require :gtk.style))
(local btn
       (button {:label :Button :vexpand false}))

(local provider (Gtk.CssProvider))
(provider:load_from_data ".red { background-color:red; } ")
;; (print :load
;;   (provider:load_from_data """
;;                            window {
;;                             background-color: green;
;;                            }
;;                            """))
;; (provider:load_from_path :style.css)
(Gtk.StyleContext.add_provider_for_screen
  (Gdk.Screen.get_default)
  provider
  Gtk.STYLE_PROVIDER_PRIORITY_USER)

(local win
  (window
    btn))

(local ctx (win:get_style_context))
(ctx:add_class :red)

