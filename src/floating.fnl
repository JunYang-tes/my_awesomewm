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
