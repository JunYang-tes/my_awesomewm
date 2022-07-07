(local awful (require :awful))
(local {: tag} awful)
(local {: prompt } (require :ui.prompt)) 
(local {: root } (require :awesome-global)) 
(local {: map : find-index } (require :utils.list)) 

(fn create []
  (print :will create tag)
  (print awful.screen.focused)
  (local t (tag.add "tag" 
                    {
                      :selected true
                      :screen (awful.screen.focused)
                      :layout awful.layout.suit.tile})) 
  (t:view_only))  

(fn name-tag []
  (print :name-tag)
  (prompt {
           :prompt "<b>Tag name:</b>"
           :on-finished (fn [name]
                          (local tag (-> (awful.screen.focused)
                                         (. :selected_tag))) 
                          (set tag.name name))})) 
            

(fn view-tag []
  (local tags (root.tags))
  (print :tags tags)
  (local tags-name (map tags (fn [t i ] (.. i " " t.name)))) 
  (awful.spawn.easy_async 
    (..
      "bash -c '"
       "cat > /tmp/tags << EOL\n" 
       (table.concat tags-name "\n")
      "\nEOL\n"
      "cat /tmp/tags | rofi -dmenu" 
      "'") 

    (fn [stdout stderr reason code] 
      (local ind (-> stdout
                     (string.match "(%d+)%s") 
                     (tonumber))) 
      (print (. tags ind))
      (if ind 
        (-> (. tags ind) 
            (: :view_only)))))) 

{ : create
  : name-tag 
  : view-tag}           
