(local list (require :utils.list))
(local {: focus } (require :utils.wm))
(local {: cairo } (require :widgets))
(local tag (require :tag))
(fn get-icon [client]
  (when (> (length client.icon_sizes) 0)
    (let [(ok icon) (pcall #(client:get_icon 1))]
      (when (and ok icon)
        (-> icon
            tostring
            (string.match "0x%x+")
            (string.sub 3)
            (tonumber 16)
            cairo.from_ptr)))))
{:window {:label :Window
          :exec (fn []
                  (-> (_G.client.get)
                      (list.filter #(and (not $1.skip_taskbar)
                                         (or (= $1.type :normal)
                                             (= $1.type :dialog)
                                             (= $1.type :splashscreen))))
                      (list.map #(do
                                   {:label $1.name
                                    :image (get-icon $1)
                                    :exec (fn []
                                            ($1:raise)
                                            (focus $1)
                                            (tag.switch-tag $1.first_tag))}))))}}
