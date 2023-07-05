(local awful (require :awful))
(local beautiful (require :beautiful))
(local {: container
        : layout
        : widget} (require :ui.builder))
(local wibox (require :wibox))
(local { : assign! } (require :utils.table))
(local ui (require :utils.ui))
(local signal (require :utils.signal))
(local { : dpi} (require :utils.wm))
(local screen-utils (require :utils.screen))
(local battery (require :components.battery))
(local volume (require :components.volume))

(local bar-height (dpi 40))
(local bar-offset-y (dpi 30))

(fn get-bar-geometry []
  (local screen (awful.screen.focused))
  (local { : width : height} screen.geometry))

(fn tag-indicator []
  (local tag-name (wibox.widget
                    (widget.textbox {:markup ""})))
  (signal.connect-signal "tag::selected"
    (fn [tag]
      (set tag-name.markup tag.name)))
  (signal.connect-signal "tag::rename"
    (fn [tag _ new-name]
      (set tag-name.markup new-name)))
  (signal.connect-signal "tag::update"
                         (fn []
                           (let [screen (awful.screen.focused)]
                             (set tag-name.markup
                                  (. screen :selected_tag :name)))))
  (layout.fixed-horizontal
    {:spacing 2}
    (container.background
      (widget.font-icon "sell"))
    tag-name))

(local function-bar
  (awful.popup
    (assign!
      {
        :widget (wibox.widget
                  ;;(container.place
                  ;;  {
                  ;;    :shape (ui.rrect 10)
                  ;;    :forced_width (. (awful.screen.focused) :geometry :width)}
                    (container.background
                      {
                       :-id :bar-container
                       :forced_height bar-height
                       :bg beautiful.wibar_bg}
                      (container.margin
                        { :left (dpi 10) :right (dpi 10)}
                        (layout.fixed-horizontal
                          {
                            :spacing (dpi 16)}
                          (tag-indicator)
                          (battery.widget)
                          (layout.fixed-horizontal
                            { :spacing (dpi 2)}
                            (widget.font-icon "date_range")
                            (widget.text-clock))
                          (volume.widget)
                          (container.margin
                            {:top (dpi 10) :right (dpi 10)}
                            (do
                              (local systray (wibox.widget.systray))
                              (systray:set_base_size (dpi 10))
                              systray))))))

        :border_width 0
        :bg :#fff00000
        :type "dock"
        :ontop true
        :shape (ui.rrect (dpi 10))
        :visible false}
      (get-bar-geometry))))

;; update x when width changed
(function-bar:connect_signal "property::width"
  (fn []
    (local screen (awful.screen.focused))
    (local {: width} (function-bar:geometry))
    (local pos (screen-utils.calc-pos
                 screen
                (/ (- screen.geometry.width width) 2)
                (- screen.geometry.height bar-offset-y bar-height)))
    (assign!
      function-bar
      pos)))

(fn toggle-visible []
  (local screen (awful.screen.focused))
  (local {: width} (function-bar:geometry))
  (local pos (screen-utils.calc-pos
               screen
              (/ (- screen.geometry.width width) 2)
              (- screen.geometry.height bar-offset-y bar-height)))
  (signal.emit "volumn::update")
  (signal.emit "tag::update")
  (assign!
    function-bar
    {:visible (not function-bar.visible)
     :x pos.x
     :y pos.y}))

{ : toggle-visible}
