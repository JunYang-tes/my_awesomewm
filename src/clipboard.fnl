(import-macros {: unmount : defn : effect} :lite-reactive)
(import-macros {: css-gen } :css)
(import-macros {: global-css : css
                : global-id-css } :gtk)
(import-macros {: catch-ignore : catch} :utils)
(local timer (require :utils.timer))
(local {: run
        : use-built
        : foreach} (require :lite-reactive.app))
(local {: window
        : box
        : label
        : list-view
        : picture
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

(local max-save-count 500)


(local clipboard-items
  ;; :content string
  ;; :sub
  ;; :mime_types
  ;; :type :text

  ;; :content string
  ;; :sub
  ;; :mime_types
  ;; :type :text
  (value []))

(fn load-saved-clipboard-items []
  (case (io.open (.. cfg.cfg_dir "clipboard.dat") :r)
    f (let [data (f:read :*all)
            decoded (msgpack.decode data)]
        (-> decoded
          (list.map
            (fn [item]
              (assign item
                      (match item.type
                        :image {:texture (gtk.texture_from_bytes item.texture)}
                        _ {}))))
          clipboard-items))))

(fn save-clipboard-items [items]
  (with-open [out (io.open (.. cfg.cfg_dir "clipboard.dat") :w)]
    (-> items
      (list.slice 1 max-save-count)
      (list.map
        (fn [item]
          (assign item
                  (match item.type
                    :image {:texture (item.texture:save_bytes)}
                    _ {}))))
      msgpack.encode
      out:write)))

(fn mime-satisfy [predict]
  (fn [mime_types] 
    (print :mime_types (inspect mime_types))
    (list.some mime_types predict)))

(local has-html 
  (mime-satisfy
    (fn [item]
      (print :has-html (inspect item))
      (stringx.includes item :html))))

(local clipboard (gtk.clipboard))
(clipboard:connect_changed
  (timer.debounce
    (fn []
      (let [mime_types (clipboard:get_mime_types)]
        (when (list.some mime_types #(stringx.starts-with $1 :text))
          (clipboard:get_text
            (fn [txt]
              (when (not= nil txt)
                (let [curr (clipboard-items)]
                  (table.insert curr 1 {:content txt
                                        :sub (string.sub txt 1 100)
                                        :mime_types 
                                          (list.filter mime_types
                                                       ;; ... application/vnd.portal.filetransfer
                                                       ;; can't paste in dolphin, filter it out
                                                       #(not= $1 :application/vnd.portal.filetransfer))
                                        :type :text})
                  (clipboard-items
                    (list.map curr #$1)))))))
        (when (list.some mime_types #(stringx.starts-with $1 :image))
          (clipboard:get_texture
            (fn [texture]
              (let [curr (clipboard-items)]
                (table.insert curr 1 {:texture texture
                                      :sub "Image"
                                      :mime_types mime_types
                                      :type :image})
                (clipboard-items
                  (list.map curr #$1))))))))
    100))
                    
(fn update-remark [index remark]
  (let [items (clipboard-items)
        item (. items index)]
    (tset item :remark remark)
    (save-clipboard-items)))
(fn send_ctrl_v []
  (_G.root.fake_input :key_press :Control_L)
  (_G.root.fake_input :key_press :v)
  (_G.root.fake_input :key_release :Control_L)
  (_G.root.fake_input :key_release :v))

(fn send_ctrl_shift_v []
  (_G.root.fake_input :key_press :Control_L)
  (_G.root.fake_input :key_press :Shift_L)
  (_G.root.fake_input :key_press :v)
  (_G.root.fake_input :key_release :Control_L)
  (_G.root.fake_input :key_release :Shift_L)
  (_G.root.fake_input :key_release :v))

(fn is-terminal [client]
  (or (= client.class :kitty)
      (= client.class :tilda)
      (= client.class :dev.warp.Warp)))


(local visible (value false))
(local selected-index (value 0))
(local paste-target (value nil))
(local input (value ""))
(local filtered-item (mapn [input clipboard-items]
                           (fn [[input items]]
                             (-> items
                                 (list.map (fn [item index]
                                             (tset item :index index)
                                             item))
                                 (list.filter 
                                   #(stringx.includes
                                      $1.sub input))))))

(fn move-to-first [index]
  (let [items (clipboard-items)
        i (. items index)]
    (table.remove items index)
    (table.insert items 1 i)
    (clipboard-items (list.map items #$1))))

(fn paste [list index]
  (when (<= index (length list))
    (tset _G.client :focus (paste-target))
    (let [item (. list index)]
      (match item.type
        :text (clipboard:set_text_content 
                item.mime_types
                item.content)
        :image (clipboard:set_texture item.texture))
      (if (is-terminal (paste-target))
        (send_ctrl_shift_v)
        (send_ctrl_v))
      (move-to-first item.index))))

(fn execute-paste [index]
  (visible false)
  (timer.set-timeout
    #(do 
       (paste (filtered-item)
          index)
       (save-clipboard-items (clipboard-items)))
    0.2))

(defn detail
  (local text (value ""))
  (box
    {:visible (map props.item #(not= $1 nil))
     :size_request [500 0]
     :hexpand true}
    (scrolled-window
      {:hexpand true
       ;:max_content_width 500
       :vexpand true}
      (map props.item (fn [item]
                        (if (= nil item)
                          (label {:label "Empty"})
                          (match item.type
                            :image (picture {:texture item.texture
                                             :can_shrink false
                                             :content_fit consts.ContentFit.Contain})
                            :text (if (has-html item.mime_types)
                                    (label {:markup item.content})
                                    (label {:text item.content})))))))
    (label {:markup (map props.item
                         #(.. "<b>Mime types:</b>"
                              (table.concat (or (?. $1 :mime_types)
                                                []))))
            :halign consts.Align.Start})
    (label {:label :Remark
            :halign consts.Align.Start})
    (entry 
      {:connect_change (fn [txt]
                         (text txt))
       :connect_key_pressed_capture
       (fn [_ code]
         (match (tonumber code)
           consts.KeyCode.enter (let [onRemarkUpdate (props.onRemarkUpdate)]
                                  (print :enter onRemarkUpdate)
                                  (onRemarkUpdate (text)))))})))
(defn clipboard-root
  (local selected-item (mapn [filtered-item selected-index]
                             (fn [[items index]]
                               (. items (+ 1 index)))))
  (window
      {: visible
       :title "Clipboard"
       :size_request [500 500]
       :connect_focus_out (fn [] (visible false))
       :connect_close_request 
       (fn [] 
         (visible false)
         true)
       :role "pop-up"}
      (box
        (entry
          {:connect_map (fn [entry]
                          (entry:set_text "")
                          (entry:grab_focus))
           :connect_change (fn [txt] (input txt))
           :connect_key_pressed_capture 
             (fn [_ code state]
               (match (tonumber code)
                 consts.KeyCode.esc (visible false)
                 consts.KeyCode.enter (execute-paste (+ 1 (selected-index)))))})
                                                   
        (box
          {:orientation consts.Orientation.Horizontal}
          (scrolled-window
            {:vexpand true
             :size_request [300 0]}
            (list-view
              {
                :data filtered-item
                :show_separators true
                :render (fn [item]
                          (box
                            {:connect_click_release 
                             (fn []
                               (let [index (. (item) :index)]
                                 (selected-index (- index 1))))}
                                 ;(execute-paste index)))}
                            (map item
                                 (fn [item]
                                   (match item.type
                                     :text (label {:label item.sub
                                                   :xalign 0})
                                     :image (box {:size_request [100 100]
                                                  :orientation consts.Orientation.Horizontal
                                                  :valign consts.Align.Center
                                                  :halign consts.Align.Start
                                                  :vexpand false :hexpand false}
                                              (picture {:texture item.texture})))))))}))
          (detail {:item selected-item
                   :onRemarkUpdate (fn [txt]
                                     (let [item (selected-item)]
                                       (print (inspect item) txt)
                                       (update-remark
                                         item.index
                                         txt)))})))))

(local win 
  (run (clipboard-root))) 
    

{:show (fn [client]
         (when (<= (length (clipboard-items)) 1)
           (load-saved-clipboard-items))
         (when (and (not= nil client)
                    (> (length (clipboard-items)) 0))
           (input "")
           (paste-target client)
           (selected-index 0)
           (visible true)))
 :is-visble (fn []
              (visible))
 :paste (fn [i]
          (execute-paste i))}
