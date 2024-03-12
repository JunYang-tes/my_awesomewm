(import-macros {: defn
                : unmount
                : effect} :lite-reactive)
(import-macros {: css-gen } :css)
(import-macros {: global-css : css
                : global-id-css } :gtk)
(local {: window
        : box
        : button
        : image
        : label } (require :gtk_.node))
(local {: run
        : use-built
        : foreach} (require :lite-reactive.app))
(local consts (require :gtk_.const))
(local { : dpi
         : click-away
         : focus
         : get-current-tag } (require :utils.wm))
(local {: get-codebase-dir} (require :utils.utils))
(local {: value
        : map-list
        : map
        : mapn} (require :lite-reactive.observable))
(local list (require :utils.list))
(local awesome-global (require :awesome-global))

(fn get-asset [name]
  (..
     (get-codebase-dir)
     "/theme/win-clastic/"
     name))

(defn start-menu-button
  (box
    (image {:from_file (get-asset :start-icon-xp.png)
            :class (css [:border "1px solid red"
                         :max-height (dpi 30)])})
    (button {:label :start})))

(defn client-item
  (local name (value (. (props.client) :name)))
  (box
    {:class (css [:max-width (dpi 100)])}
    (button
      {:label name
       :connect_size_allocate (fn [self r]
                                (let [max-width (dpi 100)
                                      h (r:height)
                                      w (r:width)]
                                  (if (> w max-width)
                                    (do
                                      (print :set_size_request)
                                      (self:set_size_request
                                        max-width (dpi 30))))))})))

(defn client-items
  (let [tag (props.tag)
        clients (value (tag:clients))]
    (fn update-clients []
      (-> (tag:clients)
          (list.filter #(and (not $1.skip_taskbar)
                             (or (= $1.type :normal)
                                 (= $1.type :dialog)
                                 (= $1.type :splashscreen))))
          clients.set))
    (awesome-global.client.connect_signal
      :manage update-clients)
    (awesome-global.client.connect_signal
      :unmanage update-clients)
    (unmount
      (awesome-global.client:disconnect_signal :manage update-clients))
    (unmount
      (awesome-global.client:disconnect_signal :unmanage update-clients))
    (box
      ;{:homogeneous true}
      (map-list clients
                #(client-item {:client $1})))))

(fn titlebar [tag visible]
  (let [screen-w tag.screen.geometry.width
        screen-h tag.screen.geometry.height]
    (run
      (window
        {: visible
         ;:default_size [screen-w (dpi 30)]
         :size_request [screen-w (dpi 30)]
         :pos [0 (- tag.screen.geometry.height
                    (dpi 30))]
         ;:decorated false
         :role :dock
         :skip_taskbar_hint true
         :type_hint consts.WindowTypeHint.Dock}
        (box
          (start-menu-button)
          (client-items {: tag}))))))

(titlebar
  (get-current-tag) true)
