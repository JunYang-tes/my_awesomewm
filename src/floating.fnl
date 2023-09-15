(local signal (require :utils.signal))
(local awful (require :awful))
(local {: taskbar} (require :theme.components))

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
