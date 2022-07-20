(local {: map} (require :utils.list))
(local awful (require :awful))

(fn select-item [{: prompt : items : on-selected}]
  (awful.spawn.easy_async 
    (..
      "bash -c '"
      "cat > /tmp/select << EOL\n" 
      (table.concat 
        (-> items 
            (map (fn [v i] (.. i " " (tostring v))))) 
        "\n") 
      "\nEOL\n" 
      "cat /tmp/select | rofi -i -dmenu -dpi " (. (awful.screen.focused ) :dpi) " -p " 
      (or prompt "Select") 
      "'") 
    (fn [stdout stderr resason code] 
      (local ind (-> stdout 
                     (string.match "(%d+)%s") 
                     (tonumber))) 
      (if ind 
        (on-selected ind))))) 

{ : select-item}
