(local awful (require :awful))
(local awesome-global (require :awesome-global))
(local {: tag} awful)
(local {: prompt } (require :ui.prompt)) 
(local {: root } (require :awesome-global)) 
(local  awesome (require :awesome-global))
(local {: map : find } (require :utils.list)) 
(local json (require :cjson)) 
(local {: filesystem } (require :gears)) 
(local wm (require :utils.wm))
;;(local wallpaper (require :utils.wallpapers)) 
(local gears (require :gears)) 
(local signal (require :utils.signal)) 

(local path "./tag.json")
(fn load-tags []
  (local default [ {:name :default}])
  (fn read []
    (let [(file msg) (io.open path "r")] 
      (if file 
        (do 
          (-> file 
            (: :read) 
            json.decode)) 
        (do 
          (print :failed-to-open-file msg) 
          default)))) 
  (print :has-config (filesystem.file_readable path))
  (if (filesystem.file_readable path) 
      (read)
      default))
          

(fn save-tags []
  (fn write [data]
    (let [(file msg) (io.open path "w")] 
         (if file 
           (do
             (file:write data) 
             (file:close)) 
           (do (print :fail-to-open msg))))) 
  (-> (root.tags)
    (map (fn [t] {:name t.name})) 
    json.encode 
    (write)))
            

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

(fn create [name]
  (local t (tag.add (or name "tag") 
                    {
                      :selected false
                      :screen (awful.screen.focused)
                      :layout awful.layout.suit.tile})) 
  (t:connect_signal "property::selected" handle-switch-tag-focus)
  (t:connect_signal "property::selected"
    (fn [tag] 
      (if tag.selected 
          (signal.emit "tag::selected" tag)))) 
  ;;(t:connect_signal "property::selected"
  ;;  (fn [tag] 
  ;;    (if tag.selected
  ;;      (wm.on-idle #(gears.wallpaper.maximized (wallpaper.get-random t)))))) 
  ;;    ;(gears.wallpaper.maximized (wallpaper.get-random t)))) 
  (save-tags)
  (t:view_only))  

(fn name-tag []
  (prompt {
           :prompt "<b>Tag Name:</b>"
           :on-finished (fn [name]
                          (local tag (-> (awful.screen.focused)
                                         (. :selected_tag))) 
                          (signal.emit "tag:rename" tag tag.name name)
                          (set tag.name name) 
                          (save-tags))})) 
(fn select-tag [{: on-selected : prompt}]
  (local tags (root.tags))
  (local tags-name (map tags (fn [t i ] (.. i " " t.name)))) 
  (awful.spawn.easy_async 
    (..
      "bash -c '"
       "cat > /tmp/tags << EOL\n" 
       (table.concat tags-name "\n")
      "\nEOL\n"
      "cat /tmp/tags | rofi -dmenu -p "
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
  (tag:view_only)) 

(fn switch-by-index [index]  
  (local tag (. (root.tags) index)) 
  (if tag 
    (switch-tag tag))) 

(fn view-tag []
  (select-tag { :on-selected switch-tag}))

(fn init []
  (each [_ tag-info (ipairs (load-tags))] 
    (create tag-info.name))) 

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
