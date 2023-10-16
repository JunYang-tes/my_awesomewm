(local gears (require :gears))
(local utils (require :utils.utils))
(local {: popup
        : imagebox} (require :ui.node))
(local {: run } (require :lite-reactive.app))
(local {: cairo } (require :lgi))
(local {: value}
       (require :lite-reactive.observable))
(local signal (require :utils.signal))
(local inspect (require :inspect))
(local {: keys} (require :utils.table))
(fn set-wallpaper
  [tag]
  (let [screen-w tag.screen.geometry.width
        screen-h tag.screen.geometry.height
        visible (value true)
        path (..
                    (utils.get-codebase-dir)
                    "/theme/win-clastic/wallpaper.jpg")]
    (fn select-tag [t]
      (when (= t tag)
        (if t.selected
          (visible true)
          (visible false))))
    (signal.connect-signal
      :tag::selected
      select-tag)
    (signal.connect-signal
      :tag::unselect
      select-tag)
    (run
      (popup
        {:screen tag.screen
         :ontop false
         :width screen-w
         :height screen-h
         :onButtonRelease (fn [self y x button]
                            (signal.emit
                              :wallpaper::click x y button))
         :bgimage (fn [ctx cr w h]
                    (let [surf (gears.surface.load path)
                          (sw sh) (gears.surface.get_size surf)]
                      (cr:scale
                        (/ screen-w sw)
                        (/ screen-h sh))
                      (cr:set_source_surface surf 0 0)
                      (tset cr :operator
                            cairo.Operator.SOURCE)
                      (cr:paint)))
         : visible}))))


{: set-wallpaper}
