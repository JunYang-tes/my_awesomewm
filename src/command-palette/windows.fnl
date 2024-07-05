(local list (require :utils.list))
(local {: focus } (require :utils.wm))
(local {: cairo } (require :widgets))
(local gtk (require :libgtk-lua))
(local tag (require :tag))
(local screen-utils (require :utils.screen))
(fn get-icon [client]
  (when (> (length client.icon_sizes) 0)
    (let [(ok icon) (pcall #(client:get_icon 1))]
      (when (and ok icon)
        (-> icon
            tostring
            (string.match "0x%x+")
            (string.sub 3)
            (tonumber 16)
            gtk.texture_from_cairo_ptr)))))
{:window {:label :Window
          :exec (fn []
                  (-> (_G.client.get)
                      (list.filter #(and (not $1.skip_taskbar)
                                         (or (= $1.type :normal)
                                             (= $1.type :dialog)
                                             (= $1.type :splashscreen))))
                      (list.map #(do
                                   {:label $1.name
                                    :description (.. "Tag:" (or (?. $1 :first_tag :name) "N/A")
                                                     " "
                                                     "Screen: " (screen-utils.get-name $1.screen))
                                    :image (get-icon $1)
                                    :exec (fn []
                                            ($1:raise)
                                            (focus $1)
                                            (tag.switch-tag $1.first_tag))}))))}}
