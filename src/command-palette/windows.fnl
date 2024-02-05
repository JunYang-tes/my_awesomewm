(local list (require :utils.list))
(local {: focus } (require :utils.wm))
(local tag (require :tag))
{:window {:label :Window
          :exec (fn []
                  (-> (_G.client.get)
                      (list.filter #(and (not $1.skip_taskbar)
                                         (or (= $1.type :normal)
                                             (= $1.type :dialog)
                                             (= $1.type :splashscreen))))
                      (list.map #(do
                                   {:label $1.name
                                    :exec (fn []
                                            ($1:raise)
                                            (focus $1)
                                            (tag.switch-tag $1.first_tag))}))))}}
