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
(local widgets (require :widgets))
(local app (widgets.fltk.app))
(local win (widgets.fltk.win))
(win:show)
(_G.awesome.connect_signal :refresh #(app:wait))

(fn setup-global-keys []
  (local ks (require :key-bindings))
  (root.keys ks))

(print
  (pcall #(do
            (let [m (require :widgets)]
              (print
                (m.hello :hello))))))

;; TODO
;; move focus
;; search key
;; exit fullscreen when new window was opened
(setup-global-keys)
(tag:init)
(wp.wp-each-screen)
