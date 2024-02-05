(local awful (require :awful))
(local hotkeys-popup (require :awful.hotkeys_popup))
(local focus-win (require :windows.focus-win))
(local swap-win (require :windows.swap))
(local gears (require :gears))
(local awesome-global (require :awesome-global))
(local {: terminal : modkey} (require :const))
(local tag (require :tag))
(local {: save-tags} tag)
(local {: range
        : find} (require :utils.list))
(local wibox  (require :wibox))
(local {: prompt } (require :ui.prompt))
(local bar (require :components.function-bar))
(local client (require :client))
(local naughty (require :naughty))
(local {: tag-untaged} (require :client))
(local cmd-palette (require :command-palette.palette_))
(local mouse (let [(ok? data) (pcall #(require :mouse.main))]
               (if ok?
                 data
                 {:run (fn [] (print (.. "Failed to load mouse module,internal error is :"
                                         (tostring data))))})))
(local {: view-tag } (require :command-palette.tag))
(local {: applications } (require :command-palette.applications))
(local jd (require :components.jd))
(local wm (require :utils.wm))
(local {: weak-key-table} (require :utils.table))
(local win-clastic-taskbar (require :theme.win-clastic.taskbar))
(local signal (require :utils.signal))
(local {: win-switcher} (require :theme.components))
(local inspect (require :inspect))


(fn run-lua []
  (prompt {
           :prompt "Run Lua:"
           :on-finished
             (fn [content]
               (local src
                (table.concat
                   [
                    "local inspect = require(\"inspect\")"
                    "local awful = require(\"awful\")"
                    "local naughty = require(\"naughty\")"
                    content] "\n"))
               (print src)
               (awful.util.eval src))}))
(fn key [...]
  { :is-key-define true
    :key-define (awful.key ...)})

(fn get-key-define [v]
  (if v.is-key-define
      v.key-define))

(fn join-keys [...]
  (local inspect (require :inspect))
  (var keys {})
  (each [i v (ipairs [...])]
    (let [ key-define (get-key-define v)]
      (if key-define
        (set keys (gears.table.join keys key-define))
        (each [_ i (ipairs v)]
          (set keys (gears.table.join keys (get-key-define i)))))))
  keys)


(local toggle-desktop
  (do
    (var show-desktop false)
    (var last-tag nil)
    (fn []
      (if last-tag
          (do
            (last-tag:view_only)
            (set last-tag nil))
          (do
            (set last-tag (-> (awful.screen.focused)
                              (. :selected_tag)))
            (awful.tag.viewnone))))))

(join-keys
  (icollect [i _ (ipairs (range 1 10 1))]
     (key [modkey] (.. "#" (+ i 9)) #(tag.switch-by-index i)
       { :description (.. "Switch to tag " i)
         :group "tag"}))
  (key [modkey] "p" cmd-palette.run
       {:description "Open command palette"
        :group "awesome"})
  (key [modkey] "Left" awful.tag.viewprev
       { :description "View previous"
         :group "tag"})
  (key [modkey] "Right" awful.tag.viewnext
       { :description "View next"
         :group "tag"})
  (key [modkey] "Escape" awful.tag.history.restore
       { :description "Go back"
         :group "tag"})
  (key [modkey] "f" nil #(focus-win.launch false)
       { :description "Focus window"
         :group "client"})
  (key [modkey "Shift"] "f" (fn []
                             (local client awesome-global.client.focus)
                             (when client
                               (if (= client.first_tag.layout awful.layout.suit.floating)
                                 (set client.maximized (not client.maximized))
                                 (set client.fullscreen (not client.fullscreen)))))
       { :description "Focus window"
         :group "client"})
  (key [modkey] "s" swap-win)
  (key [modkey "Control"] "u" awful.client.urgent.jmpto
       { :description "jump to urgent client"
         :group "client"})
  (key [modkey] "Tab"
       (fn []
         (win-switcher.show
           (wm.get-current-tag))))
  (key [modkey "Control"] "Tab"
       (fn []
         (awful.client.focus.history.previous)
         (if awesome-global.client.focus
           (: awesome-global.client.focus :raise)))
       { :description "Go back"
         :group "client"})
  (key [modkey ] "Return" #(awful.spawn terminal)
       { :description "open a terminal"
         :group "launcher"})
  (key [modkey] "=" #(awful.tag.incmwfact 0.05)
       { :description "increase master width factor"
         :group "layout"})
  (key [modkey] "-" #(awful.tag.incmwfact -0.05)
       { :description "decrease master width factor"
         :group "layout"})
  (key [modkey] "h" #(client.focus-by-direction :left)
       { :description "focus left"
         :group "layout"})
  (key [modkey] "j" #(client.focus-by-direction :down)
       { :description "focus down"
         :group "layout"})
  (key [modkey] "k" #(client.focus-by-direction :up)
       { :description "focus up"
         :group "layout"})
  (key [modkey] "l" #(client.focus-by-direction :right)
       { :description "focus right"
         :group "layout"})
  ;;(key [modkey "Shift"] "h" #(awful.tag.incnmaster 1 nil true)
  ;;     { :description "increase the number of master clients"
  ;;       :group "layout"})
  ;;(key [modkey "Shift"] "l" #(awful.tag.incnmaster -1 nil true)
  ;;     { :description "decrease the number of master clients"
  ;;       :group "layout"})
  ;;(key [modkey "Control"] "h" #(awful.tag.incncol 1 nil true)
  ;;     { :description "increase the number of columns"
  ;;       :group "layout"})
  ;;(key [modkey "Control"] "l" #(awful.tag.incncol -1 nil true)
       ;; { :description "decrease the number of columns"
       ;;   :group "layout"})
  ;; (key [modkey] "space" #(awful.layout.inc 1)
  ;;      { :description "select next"
  ;;        :group "layout"})
  ;; (key [modkey "Shift"] "space" #(awful.layout.inc -1)
  ;;      { :description "select previous"
  ;;        :group "layout"})
  (key [modkey] "r" (fn []
                      (cmd-palette.run (applications.exec)))
       { :description "Run"
         :group "launcher"})
  (key [modkey] "w" #(awful.util.spawn (.. "rofi -show window -dpi " (math.ceil (. (awful.screen.focused) :dpi))))
       { :description "Run"
         :group "launcher"})
  (key [modkey] "t" (fn []
                      (cmd-palette.run (view-tag.exec)))
       { :description "Name a tag"
         :group "tag"})
  (key [modkey "Shift"] "t" tag-untaged
       { :description "Name a tag"
         :group "tag"})
  (key [modkey] "b" bar.toggle-visible
       { :description "Toggle function bar"
         :group "awesome"})
  (key [modkey] "d" jd.toggle-visible
       { :description "Toggle jd map"
         :group :others})
  (key [modkey "Shift"] "d" toggle-desktop
       { :description "Toggle desktop"
         :group "awesome"})
  (key [modkey "Shift"] "space"
       (let [map (weak-key-table)]
         (fn restore-layout [tag]
           (let [layout (or (. map tag)
                            awful.layout.suit.tile)]
             (awful.layout.set layout)
             (signal.emit :layout::un-floating tag)))
         (fn turn-to-floating [tag]
           (tset map tag tag.layout)
           (awful.layout.set awful.layout.suit.floating)
           (save-tags)
           (signal.emit :layout::floating tag))
         (fn []
           (let [tag (wm.get-current-tag)]
             (if (= tag.layout awful.layout.suit.floating)
               (restore-layout tag)
               (turn-to-floating tag))))))
         ; (awful.layout.set
         ;    awful.layout.suit.floating)))
  (key [modkey] :m mouse.run
       {:description :mouse
        :group :awesome}))
