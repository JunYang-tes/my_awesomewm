(import-macros {: defn
                : unmount
                : effect} :lite-reactive)
(local gears (require :gears))
(local list (require :utils.list))
(local awful (require :awful))
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
(local {: xp-frame
        : colors} (require :theme.win-clastic.utils))
(local { : dpi
         : focus
         : get-modkey-name
         : get-current-tag } (require :utils.wm))
(local {: modkey} (require :const))
(local keybing (require :utils.key-binding))
(local {: hybrid} (require :utils.table))
(fn slice [items index range-length]
  (let [n (math.floor (/ (- index 1)  range-length))
        start (+ (* n 1 range-length) 1)
        end (- (+ start range-length) 1)]
    (list.slice items start end)))
(defn win-switcher
  (let [size (dpi 100)
        gap (dpi 2)
        max-width (. (props.screen)
                     :geometry
                     :width)
        item-count (map props.clients #(length $1));(length (props.clients))
        count-per-row (math.floor (/ max-width (+ size gap)))
        width (map item-count
                  (fn [item-count]
                    (+ (* (+ size gap) (math.min count-per-row
                                           item-count))
                       gap)))
        slice (mapn [props.clients props.index item-count]
                    (fn [[clients index item-count]]
                      (if (< item-count count-per-row)
                        clients
                        (slice clients index count-per-row))))]
    (popup
      {:placement awful.placement.centered
       :screen props.screen
       :visible props.visible}
      (xp-frame
        {:forced_width width
         :forced_height (dpi 150)}
        (margin
          {:left (dpi 2)}
          (h-fixed
            {:spacing (dpi 2)}
            (map-list slice
                      #(let [index $2
                             client $1]
                         (place
                           {:valign :center}
                           (background
                                {:fg (map props.index
                                          #(if (= (+ 1 (% $1 count-per-row)) (+ index 1))
                                             :white
                                             :black))
                                 :forced_width size
                                 :bg (map props.index
                                          #(if (= (% (- $1 1) count-per-row) (- index 1))
                                             colors.selected-menu
                                             colors.primary))}
                                (v-fixed
                                  (place
                                    (imagebox {:forced_height (* size 0.7)
                                               :forced_height (* size 0.7)
                                               :image (client:get_icon 1)}))
                                  (place
                                    (textbox {:markup client.name
                                              :forced_height (dpi 20)})))))))))))))

(let [switcers {}]
  (fn get [tag]
    (. switcers tag))
  (fn set-switcher [tag switcher]
    (tset switcers tag switcher))
  (fn hide [tag]
    (let [switcher (get tag)]
      (when switcher
        (switcher.visible false))))
  (fn view-client [clients index]
    (each [i c (ipairs clients)]
      (when (= i index)
        (if c.minimized
          (tset c :minimized false))
        (c:raise))))
  (fn setup-keygrabber [switcher]
    (let [index switcher.index
          visible switcher.visible
          previous-client switcher.previous-client
          clients switcher.clients]
      (fn set-index [kind]
              (let [curr (index)
                    max (length (clients))
                    new (case kind
                          :inc (let [n (+ curr 1)]
                                 (if (> n max)
                                   1
                                   n))
                          :dec (let [n (- curr 1)]
                                 (if (= n 0)
                                   max
                                   n)))]
                (index new)))
      (if (visible)
        (do
          (view-client (clients) 1)
          (awful.keygrabber
                  {
                   :keypressed_callback (fn [_ mod key]
                                          (when (= key :Tab)
                                            (if (list.some mod #(= $1 :Shift))
                                              (set-index :dec)
                                              (set-index :inc))
                                            (view-client (clients) (index))))
                   :stop_key modkey
                   :stop_event :release
                   :autostart true
                   :stop_callback #(do
                                     (visible false)
                                     (let [c (. (clients) (index))]
                                       (when c
                                         (previous-client _G.client.focus)
                                         (focus c)
                                         (c:raise))))})))))
  (fn show [tag]
    (when (= tag.layout awful.layout.suit.floating)
      (let [switcher (get tag)]
        (if switcher
          (do
            (let [previous (switcher.previous-client)
                  clients (if previous
                            (list.concat [previous]
                                         (list.filter (tag:clients)
                                                      #(not= $1 previous)))
                            (tag:clients))]
              (switcher.clients clients)
              (switcher.index 1)
              (switcher.visible (> (length clients) 0)))
            (setup-keygrabber switcher))
          (let [
                index (value 1)
                previous-client (value nil)
                clients (value (tag:clients))
                visible (value (> (length (clients)) 0))
                widget
                (run
                  (win-switcher
                    {: visible
                     : clients
                     :screen tag.screen
                     : index
                     :on-hide #(visible false)}))
                switcher {: visible : widget
                          : previous-client
                          : index : clients}]
            (setup-keygrabber switcher)
            (set-switcher tag switcher))))))
  {: show
   : hide})
