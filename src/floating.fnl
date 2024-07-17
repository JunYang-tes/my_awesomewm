(local signal (require :utils.signal))
(local awful (require :awful))
(local {: taskbar
        : wallpaper} (require :theme.components))
(local {: save-tags} (require :tag))
(local wp (require :utils.wallpapers))

(signal.connect-signal
  :tag::unselect
  (fn [tag]
    (taskbar.hide tag)))
(signal.connect-signal
  :tag::selected
  (fn [tag]
    (if (= tag.layout
          awful.layout.suit.floating)
      (do
        (tset tag :_tag_wallpaper wallpaper.wallpaper)
        (taskbar.show tag)))))
(signal.connect-signal
  :layout::floating
  (fn [tag]
    (save-tags)
    (tset tag :_tag_wallpaper wallpaper.wallpaper)
    (wp.set-wallpaper-for-tag tag)
    (taskbar.show tag)))
(signal.connect-signal
  :layout::un-floating
  (fn [tag]
    (save-tags)
    (tset tag :_tag_wallpaper nil)
    (wp.set-wallpaper-for-tag tag)
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
    (let [tag client.first_tag]
      (when (= tag.layout.name
               :floating)
        (taskbar.show tag)))))
