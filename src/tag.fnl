(local awful (require :awful))
(local awesome-global (require :awesome-global))
(local {: tag} awful)
(local {: prompt } (require :ui.prompt)) 
(local {: root } (require :awesome-global)) 
(local  awesome (require :awesome-global))
(local {: map : find } (require :utils.list)) 
(local {: filesystem } (require :gears)) 
(local {: get-prefered-screen 
        : parse-interface} (require :utils.screen))
(local wm (require :utils.wm))
;;(local wallpaper (require :utils.wallpapers)) 
(local gears (require :gears)) 
(local signal (require :utils.signal)) 
(local cfg (require :utils.cfg)) 
(local inspect (require :inspect)) 
(local screen-utils (require :utils.screen))                                   

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
  (print :will-create-tag (inspect tag-info))
  (local t (tag.add tag-info.name 
                    {
                      :selected tag-info.selected
                      :screen (get-prefered-screen tag-info.screen)
                      :layout awful.layout.suit.tile})) 
  (t:connect_signal "property::selected" handle-switch-tag-focus)
  (t:connect_signal "property::selected"
    (fn [tag] 
      (if tag.selected 
        (do
          (signal.emit "tag::selected" tag) 
          (save-tags) 
          (awful.screen.focus tag.screen)
          (print :focus-that-screen))))) 
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
  (print :select-tag-rofi-dpi (. (awful.screen.focused ) :dpi))
  (awful.spawn.easy_async 
    (..
      "bash -c '"
       "cat > /tmp/tags << EOL\n" 
       (table.concat tags-name "\n")
      "\nEOL\n"
      "cat /tmp/tags | rofi -dmenu -dpi " (. (awful.screen.focused ) :dpi) " -p "
      (or prompt "Select tag")
      "'") 

    (fn [stdout stderr reason code] 
      (local ind (-> stdout
                     (string.match "(%d+)%s") 
                     (tonumber))) 
      (if ind 
        (-> (. tags ind) 
            (on-selected)))))) 
            
                           

(fn switch-tag [tag] 
  (set tag.selected false)
  (tag:view_only)) 

(fn switch-by-index [index]  
  (local tag (. (root.tags) index)) 
  (if tag 
    (switch-tag tag))) 

(fn view-tag []
  (select-tag { :on-selected switch-tag}))

(fn init []
  (print (inspect (cfg.load-cfg :tag {})))
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
  (print :swap tag)
  (select-tag 
    { :on-selected (fn [tag2] 
                     (tag:swap tag2) 
                     (local tmp tag.name) 
                     (set tag.name tag2.name) 
                     (set tag2.name tmp))})) 
 

{ : create
  : init
  : name-tag 
  : switch-tag
  : select-tag
  : swap           
  : switch-by-index 
  : view-tag}           
