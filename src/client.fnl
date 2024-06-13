(local awful (require :awful))
(local awesome-global (require :awesome-global))
(local wm (require :utils.wm))
(local timer (require :utils.timer))
(local inspect (require :inspect))
(local list (require :utils.list))
(local {: select-tag} (require :tag))
(local wibox (require :wibox))
(local tbl (require :utils.table))
(local screen-utils (require :utils.screen))
(local {: root } (require :awesome-global))
(local {: switch-tag
        : create} (require :tag))
(local default-titlebar (require :title-bars.default))
(local win-clastic (require :title-bars.win-clastic))
(local signal (require :utils.signal))

(fn normalize-client [client]
  (if (or client.fullscreen client.maximized client.maximized_vertical client.maximized_horizontal)
      (do
       (set client.fullscreen false)
       (set client.maximized false)
       (set client.maximized_vertical false)
       (set client.maximized_horizontal false)
       true)
      false))

(fn move-chrome-devtools [client]
  (if (and
        (= client.name :DevTools))
    (let [scs (length (screen-utils.get-screen-list))
          tag (list.find (root.tags) #(= $1.name "DevTool"))]
      (if (and
            (not= nil tag)
            (> scs 1))
          (do
            (client:move_to_tag tag)
            (switch-tag tag))))))

;; Add titlebar for floating tag client
(awesome-global.client.connect_signal
  :manage
  (let [handlers-for-layout
        {:floating (fn [client]
                     (tset client :titlebars_enabled true)
                     (tset client :titlebar true))
         :tile (fn [client]
                (move-chrome-devtools client)
                (local tag client.first_tag)
                (local clients (-> client
                                 (. :first_tag)
                                 (: :clients)))
                (if (and (= client.type :normal)
                         (not= client.role :cmd-palette)
                         (not client.floating))
                  (each [_ v (ipairs clients)]
                    (when (not= v client)
                      (normalize-client v)))))}]

    (fn [client]
      (let [tag client.first_tag
            layout (. tag :layout :name)
            handler (. handlers-for-layout layout)]
        (if handler
          (handler client))))))
(fn focus-previous [client]
  (when (= awesome-global.client.focus nil)
    (let [screen client.screen
          previous (or (awful.client.focus.history.get screen 0)
                       (wm.get-focusable-client client.first_tag))]
      (when previous
        (previous:emit_signal
          :request::activate
          :client.focus.history.previous 
          {:raise false})))))
(awesome-global.client.connect_signal
  :unmanage
  focus-previous)

(awesome-global.client.connect_signal
  "property::urgent"
  (fn [c]
    ; 微信有新消息会将client设为urgent
    (when (not= c.name "微信")
      (tset c :minimized false)
      (c:jump_to))))

(awesome-global.client.connect_signal
  "property::titlebar"
  (fn [c]
    (if c.titlebar
      (win-clastic c)
      ;(default-titlebar c)
      (awful.titlebar.hide c))))

(awesome-global.client.connect_signal 
  :manage
  (fn [client]
    (client:connect_signal :property::fullscreen
                            (fn [client]
                              (if client.fullscreen
                                (signal.emit :client::fullscreen client)
                                (signal.emit :client::unfullscreen client))))
    (when (= (?. client :first_tag :layout) awful.layout.suit.floating)
      (awful.placement.no_offscreen client))
    (if (= nil client.first_tag)
      (set client.first_tag
           (let [screen client.screen]
             (create { :name "(Anonymous)"
                       :screen screen
                       :selected true}))))))

(fn focus-by-direction [dir]
  (let [client awesome-global.client.focus
        screen (awful.screen.focused)]
    (if (and client
             (= client.screen screen))
      (awful.client.focus.global_bydirection dir client)
      ;; if on focused client, then focus to the next screen
      (awful.screen.focus_bydirection dir screen))))


(fn tag-untaged []
  (local untaged
    (-> (awesome-global.client.get)
      (list.filter (fn [c] (= c.first_tag nil)))))
  (if (> (length untaged) 0)
      (select-tag { :on-selected (fn [tag]
                                   (-> untaged
                                       (list.map (fn [c] (c:move_to_tag tag)))))})))


{
 : normalize-client
 : focus-by-direction
 : tag-untaged}

