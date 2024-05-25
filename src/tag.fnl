(local awful (require :awful))
(local awesome-global (require :awesome-global))
(local {: tag} awful)
(local {: prompt } (require :ui.prompt))
(local {: root } (require :awesome-global))
(local  awesome (require :awesome-global))
(local {: map : find } (require :utils.list))
(local {: filesystem } (require :gears))
(local {: get-prefered-screen
        : is-screen
        : parse-interface} (require :utils.screen))
(local wp (require :utils.wallpapers))
(local wm (require :utils.wm))
(local gears (require :gears))
(local signal (require :utils.signal))
(local cfg (require :utils.cfg))
(local inspect (require :inspect))
(local screen-utils (require :utils.screen))
(local {: select-item } (require :ui.select))
(local list (require :utils.list))
(local titlebar (require :title-bars.init))
(local mouse (require :utils.mouse))

(fn save-tags []
  (fn save []
    (fn mk-cfg [tags]
      {: tags})
    (-> (root.tags)
      (map (fn [t] {:name t.name
                    :selected t.selected
                    :floating (= t.layout awful.layout.suit.floating)
                    :screen (.. "interface:" (parse-interface t.screen))}))
      mk-cfg
      (cfg.save-cfg :tag)))
  (wm.on-idle save))

(local handle-switch-tag-focus
  (do
    (local focus-map {})
    (awesome-global.client.connect_signal 
      :unmanage
      (fn [client]
        (let [c (. focus-map client.first_tag)]
          (if (= c client)
            (tset focus-map client.first_tag nil)))))
    (awesome-global.client.connect_signal :focus
      (fn [client]
        (if (and client.focusable
                 (not= client.role :prompt))
          (tset focus-map client.first_tag client))))
    (fn get-focus [tag]
      (local client (or (. focus-map tag)
                        (wm.get-focusable-client tag)))
      (tset focus-map tag client)
      client)
    (fn [tag]
      (if tag.selected
        (wm.focus (get-focus tag))))))

(fn handle-layout-change [tag]
  (if (= tag.layout awful.layout.suit.floating)
    ;; display title bar for floating layout
    (each [_ c (ipairs (tag:clients))]
      (let [titlebar-height (titlebar.get-title-height)]
        (tset c :height (- c.height titlebar-height))
        (tset c :y (+ c.y titlebar-height)))
      (tset c :titlebar true))
    (each [_ c (ipairs (tag:clients))]
      (if (not c.floating)
        (tset c :titlebar false)))))

(fn create [tag-info]
  (local tag-info (or tag-info {:name "Anonymous"
                                :screen ":focused"
                                :selected true}))
  (local t (tag.add tag-info.name
                    {
                      :selected tag-info.selected
                      :screen (if (is-screen tag-info.screen)
                                  tag-info.screen
                                  (get-prefered-screen tag-info.screen))
                      :layout (if tag-info.floating
                                awful.layout.suit.floating
                                awful.layout.suit.tile)}))
  (t:connect_signal "property::selected" handle-switch-tag-focus)
  (t:connect_signal "property::selected"
    (fn [tag]
      (if tag.selected
        (do
          (wp.set-wallpaper-for-tag tag)
          (signal.emit "tag::selected" tag)
          (save-tags)
          (awful.screen.focus tag.screen))
        (signal.emit "tag::unselect" tag))))
  (t:connect_signal "property::layout" handle-layout-change)
  (save-tags)
  (if tag-info.selected
    (do
     (t:view_only)
     (wm.on-idle
       #(do
          (when tag-info.floating
            (signal.emit :layout::floating t))
          (signal.emit "tag::selected" t)))))
  t)

(fn name-tag []
  (prompt {
           :prompt "<b>Tag Name:</b>"
           :on-finished (fn [name]
                          (local tag (-> (awful.screen.focused)
                                         (. :selected_tag)))
                          (signal.emit "tag::rename" tag tag.name name)
                          (set tag.name name)
                          (save-tags))}))
(fn select-tag [{: on-selected : prompt}]
  (local tags (root.tags))
  (local tags-name (map tags (fn [t i ] (.. i
                                            " "
                                            (screen-utils.get-name t.screen)
                                            " "
                                            (or t.name "Anonymous")))))
  (select-item
    {
      :items tags-name
      :prompt "Select tag"
      :on-selected
        (fn [index]
          (if index
            (-> (. tags index)
                on-selected)))}))

(fn switch-tag [tag]
  (let [current (wm.get-current-tag)
        current_screen current.screen
        tgt-screen tag.screen]
    (when (not= tgt-screen current_screen)
      (mouse.move-to-screen tgt-screen))
    (tset tag :selected true)
    (tag:view_only)))

(fn switch-by-index [index]
  (local tag (. (root.tags) index))
  (if tag
    (switch-tag tag)))

(fn view-tag []
  (select-tag { :on-selected switch-tag}))

(fn move-to-another-screen []
  (local [s1 s2] (screen-utils.get-screen-list))
  (local tag (wm.get-current-tag))
  (local tgt-screen
    (if (= tag.screen s1)
        s2
        s1))
  (set tag.screen tgt-screen)
  (switch-tag tag)
  (awful.screen.focus tgt-screen))

(fn move-to-screen []
  (local screens (icollect [ k v (pairs (screen-utils.get-screens))]
                   v))
  (if (= (length screens)
         2)
      (move-to-another-screen)
      (select-item
        {
          :items (-> screens
                     (map (fn [s]
                            (screen-utils.get-name s))))
          :prompt "Select screen"
          :on-selected
            (fn [index]
              (local s (. screens index))
              (local tag (wm.get-current-tag))
              (set tag.screen s))})))
(fn handle-screen-change []
  (awful.screen.connect_for_each_screen
    (fn [screen]
      ;; may be restore tags?
      (create {:name "Default"
               :screen screen}))))

(fn init []
  (let [ def-tags (icollect [k _ (pairs (screen-utils.get-screens))]
                    {:name "Default"
                     :floating false
                     :screen (.. "interface:" k)})
        tag-config (cfg.load-cfg :tag {
                                       :tags def-tags})
        tags (if (= 0 (length tag-config.tags))
                def-tags
                tag-config.tags)]
    (each [_ tag-info (ipairs tags)]
      (create tag-info))
    (each [k screen (pairs (screen-utils.get-screens))]
      (if (= (length screen.tags)
             0)
        (do
         (create {:name "Default"
                  :screen (.. "interface:" k)}))))))

(fn swap []
  (local tag (-> (awful.screen.focused)
                 (. :selected_tag)))
  (select-tag
    { :on-selected (fn [tag2]
                     (tag:swap tag2)
                     (local tmp tag.name)
                     (set tag.name tag2.name)
                     (set tag2.name tmp))}))
(fn delete []
  (-> (awful.screen.focused)
      (. :selected_tag)
      (: :delete)))

{ : create
  : delete
  : save-tags
  : init
  : name-tag
  : switch-tag
  : select-tag
  : swap
  : switch-by-index
  : view-tag
  : move-to-screen
  : move-to-another-screen}
