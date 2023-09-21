(import-macros {: defn
                : unmount
                : effect} :lite-reactive)
(local awesome-global (require :awesome-global))
(local wibox (require :wibox))
(local awful (require :awful))
(local {: hybrid} (require :utils.table))
(local {: run } (require :lite-reactive.app))
(local {: value
        : map-list
        : map
        : mapn} (require :lite-reactive.observable))
(local wibox (require :wibox))
(local inspect (require :inspect))
(local {: wibar
        : textbox
        : textclock
        : checkbox
        : events
        : factory
        : popup
        : place
        : systray
        : margin
        : client-icon
        : imagebox
        : constraint
        : h-flex
        : h-align
        : v-align
        : rotate
        : h-fixed
        : v-fixed
        : background} (require :ui.node))
(local {: colors
        : button-container
        : xp-frame } (require :theme.win-clastic.utils))
(local win-utils (require :theme.win-clastic.utils))
(local base (require :wibox.widget.base))
(local { : dpi
         : click-away
         : focus
         : get-current-tag } (require :utils.wm))
(local beautiful (require :beautiful))

(local button (factory.one-child-container
                button-container
                events))
(local {: get-codebase-dir} (require :utils.utils))
(local xp-frame win-utils.xp-frame)
(local keybing (require :utils.key-binding))
(local signal (require :utils.signal))


(local container
  (factory.one-child-container
    (fn titlebar-container []
      (let [widget (base.make_widget nil nil {:enable_properties true})
            private {}]
        (fn get-child []
          (. widget :widget))
        (tset widget :draw
              (fn [_ ctx cr width height]
                (cr:set_source colors.primary)
                (cr:rectangle 0 0 width height)
                (cr:fill)
                (cr:set_line_width 2)
                (cr:set_source colors.line-white)
                (cr:move_to 0 0)
                (cr:line_to width 0)
                (cr:stroke)))
        (tset widget :layout
              (fn [_ _ w h]
                (let [child (get-child)]
                  (if child
                    [(base.place_widget_at
                       child
                       0 0
                       w h)]
                    []))))
        widget))))

(fn get-asset [name]
  (..
     (get-codebase-dir)
     "/theme/win-clastic/"
     name))


(defn client-item
  (local focused (value false))
  (let [c (props.client)]
    (c:connect_signal "unfocus"
                      #(focused false))
    (c:connect_signal "focus"
                      #(focused true)))
  (button
    {
     :pressed focused
     :forced_width 250
     :onButtonPress (fn []
                      (let [c (props.client)]
                        (if (not= awesome-global.client.focus c)
                          (do
                            (c:raise)
                            (focus c))
                          (tset c :minimized true))))}
    (h-fixed
      (place
        {:valign :center
         :halign :center}
        (margin {:left (dpi 2)
                 :right (dpi 2)}
          (constraint
            {:width (dpi 20)
             :height (dpi 20)}
            (client-icon {:client props.client}))))
      (background
        {:fg :black}
        (textbox {:markup (map props.client
                               #(. $1 :name))})))))

(defn clients
  (let [tag (props.tag)
        clients (value (tag:clients))]
    (fn update-clients []
      (print :update-clients)
      (clients (tag:clients)))
    (awesome-global.client.connect_signal
      :manage update-clients)
    (awesome-global.client.connect_signal
      :unmanage update-clients)
    (unmount
      (awesome-global.client:disconnect_signal :manage update-clients))
    (unmount
      (awesome-global.client:disconnect_signal :unmanage update-clients))
    (h-fixed
      (map-list clients
        #(do
           (margin
            {:top (dpi 2)
             :bottom (dpi 2)
             :left 2
             :right 2}
            (client-item
              {:client $1})))))))
(defn menu-item
  (win-utils.menu-item
    (h-fixed
      {:onButtonRelease props.on-click}
      (margin
        {:right (dpi 10)}
        (imagebox {:image (map props.image
                               get-asset)
                   :forced_width (dpi 30)
                   :forced_height (dpi 30)}))
      (textbox {:markup props.text}))))
(let [a 1
      b (+ a 1)
      c (fn []
          (+ a 1))]
  :TDO)
(defn start-menu
  (local hide #(((props.on-close))))
  (let [popover
        (popup
          {:visible props.visible
           :screen props.screen
           :placement (fn [c]
                        (awful.placement.bottom_left
                          c
                          {:margins {:bottom (dpi 30)}}))}
          (margin
            (xp-frame
              {:forced_width (dpi 200)
               :onButtonRelease props.on-close}
              (margin 
                {:letf (dpi 2)
                 :right (dpi 2)
                 :top (dpi 2)
                 :bottom (dpi 2)}
                (h-fixed
                  (rotate
                    {:direction :east}
                    (background
                      {:fg :white
                       :bg :#000080}
                      (margin
                        {:left (dpi 4)
                         :top (dpi 4)
                         :bottom (dpi 4)}
                        (textbox {:markup "Arch Linux Unprofessional"}))))
                  (background
                    {:fg :#000000}
                    (v-fixed
                      (menu-item {:image :shutdown.png
                                  :text :Run...
                                  :on-click #(print :RUN)})
                      (menu-item {:image :shutdown.png
                                  :on-click #(awful.spawn "pkexec systemctl suspend -i")
                                  :text :Shutdown...}))))))))]
    (print :props.on-click props.on-close)
    (effect [props.visible]
            (if (props.visible)
              (click-away popover
                          hide)))
    popover))

(fn titlebar [screen tag visible]
  (let [cnt (value 0)
        start-menu-visible (value false)]
    (run
      (wibar
        {: screen
         : visible
         :height (dpi 30)
         ; :height (map visible
         ;              #(if $1 (dpi 30) 0.1))
         :ontop true
         :position :bottom}
        ;(container)
        (margin
          (container
            (h-align
              (margin
                {:left (dpi 4)
                 :top (dpi 2)
                 :bottom (dpi 2)}
                (button
                  {
                   :forced_width 150
                   :pressed start-menu-visible
                   :onButtonPress (fn []
                                    (start-menu-visible (not (start-menu-visible)))
                                    (print :press))}
                  (h-fixed
                    (margin
                      {:left (dpi 4)}
                      (place
                        {:halign :center}
                        (imagebox
                          {:image (get-asset :start-icon-xp.png)
                           :forced_height (dpi 20)
                           :forced_width (dpi 20)})))
                    (place
                      {:halign :center
                       :valign :center}
                      (background
                        {:fg :#000}
                        (textbox {:markup :Start
                                  :font "Tahoma 14 bold"
                                  :halign :center}))))))
              (clients {: tag})
              (margin
                {:top (dpi 2)
                 :bottom (dpi 2)
                 :left (dpi 2)
                 :right (dpi 2)}
                (button
                  {:pressed true}
                  (background
                    {:fg :#000}
                    (h-fixed
                      (margin {:left (dpi 2)}
                        (win-utils.systray))
                      (textclock {:format "%H:%M"}))))))))))
    (run
      (start-menu
        {:screen screen
         :on-close #(start-menu-visible false)
         :visible (mapn [visible start-menu-visible]
                        #(and (. $1 1)
                              (. $1 2)))}))))
(local titlebar-mgr
  (let [bars {}]
    (fn hide [tag]
      (let [
            bar (. bars
                   tag)]
        (if bar
          (bar.visible false))))
    (fn show [tag]
      (let [
            bar (. bars
                   tag)]
        (if bar
          (bar.visible true)
          (let [visible (value true)]
            (tset bars tag {: visible})
            (titlebar tag.screen tag visible)))))
    {: hide : show}))

titlebar-mgr
