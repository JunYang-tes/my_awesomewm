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

(fn save-tags []
  (fn save []
    (fn mk-cfg [tags]
      {: tags}) 
    (-> (root.tags)
      (map (fn [t] {:name t.name 
                    :selected t.selected 
                    :screen (.. "interface:" (parse-interface t.screen))}))
      mk-cfg
      (cfg.save-cfg :tag)))        
  (wm.on-idle save)) 

(local handle-switch-tag-focus 
  (do 
    (local focus-map {})
    (awesome-global.client.connect_signal :focus
      (fn [client] 
        (tset focus-map client.first_tag client))) 
    (fn get-focus [tag]
      (local client (or (. focus-map tag) 
                        (wm.get-focusable-client tag))) 
      (tset focus-map tag client) 
      client) 
    (fn [tag]
      (if tag.selected 
        (wm.focus (get-focus tag)))))) 

(fn create [tag-info]
  (local tag-info (or tag-info {:name "(Anonymous)"
                                :screen ":focused" 
                                :selected true})) 
  (local t (tag.add tag-info.name 
                    {
                      :selected tag-info.selected
                      :screen (if (is-screen tag-info.screen)
                                  tag-info.screen 
                                  (get-prefered-screen tag-info.screen))
                      :layout awful.layout.suit.tile})) 
  (t:connect_signal "property::selected" handle-switch-tag-focus)
  (t:connect_signal "property::selected"
    (fn [tag] 
      (if tag.selected 
        (do
          (signal.emit "tag::selected" tag) 
          (save-tags) 
          (awful.screen.focus tag.screen)))))
          ;(wp.set-wallpaper tag))))) 
  ;;(t:connect_signal "property::selected"
  ;;  (fn [tag] 
  ;;    (if tag.selected
  ;;      (wm.on-idle #(gears.wallpaper.maximized (wallpaper.get-random t)))))) 
  ;;    ;(gears.wallpaper.maximized (wallpaper.get-random t)))) 
  (save-tags)
  (if tag-info.selected
    (t:view_only)))  

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
                                            t.name)))) 
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
  (set tag.selected false)
  (tag:view_only)) 

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
  (local def-tags (icollect [k _ (pairs (screen-utils.get-screens))]
                    {:name "Default" 
                     :screen (.. "interface:" k)})) 
  (local tag-config
    (cfg.load-cfg :tag {
                        :tags def-tags}))
  (each [_ tag-info (ipairs tag-config.tags)] 
    (create tag-info))) 

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
  : init
  : name-tag 
  : switch-tag
  : select-tag
  : swap           
  : switch-by-index 
  : view-tag           
  : move-to-screen 
  : move-to-another-screen}
