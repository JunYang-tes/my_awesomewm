;; got gtk4 not actully initialized if without this
(pcall #(let [lgi (require :lgi)]
          (print lgi.Gtk)))
(local widgets (require :widgets))
(local app (widgets.gtk4.app))
;(_G.awesome.connect_signal :refresh #(app:iteration))
(local gears (require :gears))
(local theme (require :theme.theme))
(local beautiful (require :beautiful))
(beautiful.init theme)
(require :theme.notification)

(local root _G.root)
(local awful (require :awful))
(local inspect (require :inspect))
(local modkey "Mod4")
(require :floating)
(local tag (require :tag))
(local {: tag-untaged} (require :client))
(local wp (require :utils.wallpapers))

(require :command-palette.load-cmds)
(require :notification)
(require :rules)
(require :components.function-bar)
(require :autorun)

(fn setup-global-keys []
  (local ks (require :key-bindings))
  (root.keys ks))


;; TODO
;; move focus
;; search key
;; exit fullscreen when new window was opened
(setup-global-keys)
(tag:init)
(wp.wp-each-screen)
