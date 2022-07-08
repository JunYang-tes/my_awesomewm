(local awful (require :awful))
(local {: tag} awful)
(local {: prompt } (require :ui.prompt)) 
(local {: root } (require :awesome-global)) 
(local  awesome (require :awesome-global))
(local {: map : find } (require :utils.list)) 
(local json (require :cjson)) 
(local {: filesystem } (require :gears)) 
(local wm (require :utils.wm))
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

(fn create [name]
  (print awful.screen.focused)
  (local t (tag.add (or name "tag") 
                    {
                      :selected true
                      :screen (awful.screen.focused)
                      :layout awful.layout.suit.tile})) 
  (save-tags)
  (t:view_only))  

(fn name-tag []
  (prompt {
           :prompt "<b>Tag Name:</b>"
           :on-finished (fn [name]
                          (local tag (-> (awful.screen.focused)
                                         (. :selected_tag))) 
                          (set tag.name name))})) 
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
      (print (. tags ind))
      (if ind 
        (-> (. tags ind) 
            (on-selected)))))) 
            
(fn get-focusable-client [tag] 
  (or (find (tag:clients ) (fn [c] c.fullscreen)) 
      (. (tag:clients) 1))) 
                           

(local switch-tag  
  (do 
    (var client nil) 
    (fn [tag] 
      (local old-focused awesome.client.focus)
      (tag:view_only) 
      (if (not client) 
          (set client (get-focusable-client tag))) 
      (if client 
          (wm.focus client)) 
      (set client old-focused)))) 

(fn view-tag []
  (select-tag { :on-selected switch-tag}))

(fn init []
  (each [_ tag-info (ipairs (load-tags))] 
    (create tag-info.name))) 
 
{ : create
  : init
  : name-tag 
  : select-tag
  : view-tag}           
