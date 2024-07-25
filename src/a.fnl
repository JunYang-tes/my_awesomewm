(import-macros { : time-it } :utils)
(import-macros {: unmount : defn : effect} :lite-reactive)
(import-macros {: css-gen } :css)
(import-macros {: global-css : css
                : global-id-css } :gtk)
(import-macros {: catch-ignore : catch} :utils)
(local timer (require :utils.timer))
(local {: run
        : use-built
        : use-widget
        : foreach} (require :lite-reactive.app))
(local {: window
        : box
        : label
        : list-view
        : icon-button
        : picture
        : fixed
        : overlay
        : scrolled-window
        : entry} (require :gtk4.node))
(local consts (require :gtk4.const))
(local list (require :utils.list))
(local stringx (require :utils.string))
(local {: value
        : map-list
        : map
        : mapn} (require :lite-reactive.observable))
(local inspect (require :inspect))
(local gtk (require :libgtk-lua))
(local wm (require :utils.wm))
(local cfg (require :utils.cfg))
(local {: assign } (require :utils.table))
(local msgpack (require :msgpack))
(local utils (require :utils.utils))
(fn convert []
  (case (io.open (.. cfg.cfg_dir "clipboard.dat") :r)
    f (let [data (f:read :*all)
            decoded (msgpack.decode data)]
        (case (io.open (.. cfg.cfg_dir "clipboard.data") :w)
          out
             (when decoded
               (-> decoded
                   (list.map
                     (fn [item]
                       (assign item
                               (match item.type
                                 :image {:texture (gtk.texture_from_bytes item.texture)
                                         :id (utils.id)}
                                 _ {:id (utils.id)}))))
                   (list.map 
                     (fn [item]
                       (when (= item.type
                                :image)
                         (item.texture:save (.. cfg.cfg_dir "clipboard/" item.id ".png")))
                       item))
                   (list.map
                     (fn [item]
                       (if (= item.type :image)
                         (tset item :texture nil))
                       item))
                   msgpack.encode
                   out:write))))))
(fn load-saved-clipboard-items []
  (case (io.open (.. cfg.cfg_dir "clipboard.data"))
    f (let [data (f:read :*all)
            decoded (msgpack.decode data)]
        (print :???? decoded)
        (list.map 
          decoded
          (fn [item]
            (assign item
                    (case item.type
                      :image {:texture (gtk.texture_from_file
                                         (.. cfg.cfg_dir "clipboard/" item.id ".png"))}
                      _ {})))))
                        
    _ []))

(time-it "load"
         (print
           (load-saved-clipboard-items)))
; (time-it "convert"
;          (convert))
