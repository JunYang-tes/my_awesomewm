(local signal (require :utils.signal))
(local awful (require :awful))
(local {: taskbar
        : set-wallpaper} (require :theme.components))
(local {: save-tags} (require :tag))

(signal.connect-signal
  :tag::unselect
  (fn [tag]
    (taskbar.hide tag)))
(signal.connect-signal
  :tag::selected
  (fn [tag]
    (if (= tag.layout
          awful.layout.suit.floating)
      (taskbar.show tag))))
(signal.connect-signal
  :layout::floating
  (fn [tag]
    (save-tags)
    (set-wallpaper tag)
    (taskbar.show tag)))
(signal.connect-signal
  :layout::un-floating
  (fn [tag]
    (save-tags)
    (taskbar.hide tag)))
(signal.connect-signal
  :client::fullscreen
  (fn [client]
    (let [tag client.first_tag]
      (when (= tag.layout.name
               :floating)
        (taskbar.hide tag)))))
(signal.connect-signal
  :client::unfullscreen
  (fn [client]
    (print :unfullscreen)
    (let [tag client.first_tag]
      (when (= tag.layout.name
               :floating)
        (taskbar.show tag)))))
