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
(local {: dpi } (require :utils.wm))

(fn px [n]
  (.. (dpi n) :px))

(local colors 
  {:primary-text :#181826
   :secondary-text :#4f4f5d})
(local utils (require :utils.utils))

(local max-save-count 500)


(local clipboard-items
  ;; :content string
  ;; :sub
  ;; :id
  ;; :mime_types
  ;; :type :text

  ;; :content Image
  ;; :id
  ;; :texture
  ;; :mime_types
  ;; :type :image
  (value []))

(fn load-saved-clipboard-items []
  (case (io.open (.. cfg.cfg_dir "clipboard.data"))
    f (let [data (f:read :*all)
            decoded (msgpack.decode data)]
        (list.map 
          (or decoded [])
          (fn [item]
            (assign item
                    (case item.type
                      :image {:texture (gtk.texture_from_file
                                         (.. cfg.cfg_dir "clipboard/" item.id ".png"))}
                      _ {})))))))

(clipboard-items (load-saved-clipboard-items))

(fn shrink-items [items]
  (let [copy (list.map items #$1)]
    ;;先删除没有备注的
    (for [i (length copy) 1 -1 &until (<= (length copy)
                                          max-save-count)]
      (let [item (. copy i)]
        (if (or (= nil item.remark)
                (= "" item.remark))
            (table.remove copy i))))
    ;; 再删除较短的
    (if (> (length copy)
           max-save-count)
      (for [i (length copy) 1 -1 &until (<= (length copy)
                                            max-save-count)]
        (let [item (. copy i)]
          (if (and (not= :image item.type)
                   (< (length item.content) 20))
              (table.remove copy i)))))
    ;; 再删除后面的
    (if (> (length copy) max-save-count)
     (list.slice copy 1 max-save-count)
     copy)))
  

(fn save-clipboard-items [items]
  (when (and items
             (> (length items)
                0))
    (let [items_to_save (if (> (length items) max-save-count)
                          (shrink-items items)
                          items)]
      (with-open [out (io.open (.. cfg.cfg_dir "clipboard.data") :w)]
        (-> items_to_save
          (list.map 
            (fn [item]
             (let [new (assign item {})]
               (when (= new.type :image)
                 (tset new :texture nil))
               new)))
          msgpack.encode
          out:write)))))

(fn mime-satisfy [predict]
  (fn [mime_types] 
    (list.some mime_types predict)))

(local has-html 
  (mime-satisfy
    (fn [item]
      (stringx.includes item :html))))

(fn is-url [content]
  (or 
    (stringx.starts-with content :http://)
    (stringx.starts-with content :ftp://)
    (stringx.starts-with content :file://)
    (stringx.starts-with content :https://)))
(fn make-link [uri]
  (string.format "<a href='%s'>%s</a>" uri uri))
  

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
                                        :id (utils.id)
                                        :sub (string.sub txt 1 100)
                                        :remark ""
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
              (let [curr (clipboard-items)
                    item {:texture texture
                                      :id (utils.id)
                                      :sub "Image"
                                      :remark ""
                                      :mime_types mime_types
                                      :type :image}]
                (texture:save (.. cfg.cfg_dir "clipboard/" item.id ".png"))
                (table.insert curr 1 item)
                (clipboard-items
                  (list.map curr #$1))))))))
    100))
                    
(fn update-remark [index remark]
  (let [items (clipboard-items)
        item (. items index)]
    (tset item :remark remark)
    (clipboard-items
      (list.map items #$1))
    (save-clipboard-items
      items)))
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
                                   #(or
                                      (stringx.includes
                                        (or $1.remark "") input)
                                      (stringx.includes
                                        $1.sub input)))))))

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
       (paste (clipboard-items)
          index)
       (save-clipboard-items (clipboard-items)))
    0.1))

(defn detail
  (local mouse-is-close-to-overlay (value false))
  (local is-image (map props.item #(and 
                                     (not= $1 nil)
                                     (= $1.type :image))))
  (local overlay-visible (mapn [mouse-is-close-to-overlay is-image]
                               (fn [[a b]]
                                 (and a b))))
  (local image-shrink (value false))
  (local find-widget (use-widget))
  (box
    {:visible (map props.item #(not= $1 nil))
     :id "preview-container"
     :size_request [500 0]
     :connect_mouse_move (fn [x y]
                           ; (let [w (find-widget :clipboard-overlay-container)
                           ;       height (w:get_height)
                           ;       width (w:get_width)]
                           ;   (print height width (: (find-widget :preview-container) :get_width)))
                           (if (< y 50)
                             (mouse-is-close-to-overlay true)
                             (mouse-is-close-to-overlay false)))
     :hexpand true}
    (overlay
      (box {:orientation consts.Orientation.Horizontal
            :id :clipboard-overlay-container
            :valign consts.Align.Start
            :visible overlay-visible}
           (icon-button {:name :zoom-original
                         :connect_click (fn []
                                          (image-shrink false))})
           (icon-button {:name :zoom-fit-best
                         :connect_click (fn []
                                          (image-shrink true))}))
      (scrolled-window
        {:hexpand true
         ;:max_content_width 500
         :vexpand true}
        (map props.item (fn [item]
                          (if (= nil item)
                            (label {:label "Empty"})
                            (match item.type
                              :image (picture {:texture item.texture
                                                 :can_shrink image-shrink
                                                 :content_fit consts.ContentFit.Contain})
                              :text (if (has-html item.mime_types)
                                      (label {:markup item.content
                                              :wrap true})
                                      (is-url item.content) (label {:markup (make-link item.content)
                                                                     :wrap true})
                                      (label {:text item.content
                                              :wrap true}))))))))
    (label {:markup (map props.item
                         #(.. "<b>Mime types: </b>"
                              (table.concat (or (?. $1 :mime_types)
                                                [])
                                            ";")))
            :halign consts.Align.Start
            :wrap true})
    (label {:markup "<b>Remark: </b>"
            :halign consts.Align.Start})
    (entry 
      {
       :placeholder "type remark here, press enter to update"
       :connect_key_pressed_capture
       (fn [_ code _ entry]
         (match (tonumber code)
           consts.KeyCode.enter (let [onRemarkUpdate (props.onRemarkUpdate)]
                                  (onRemarkUpdate (entry:text))
                                  (entry:set_text ""))))})))
(defn clipboard-root
  (local selected-item (mapn [filtered-item selected-index]
                             (fn [[items index]]
                               (. items (+ 1 index)))))
  (local remark-style (css [:font-size (px 16)
                            :color colors.secondary-text
                            :font "Hack Nerd Font"]))
  ; (local style (css [:font-size (px 16)
  ;                           :color colors.secondary-text
  ;                           :font "Hack Nerd Font"]))
  (window
      {: visible
       :title "Clipboard"
       ;:class (css [:color "red"])
       :size_request [500 500]
       :connect_focus_out (fn [] (visible false))
       :connect_close_request 
       (fn [] 
         (visible false)
         true)
       :role "pop-up"}
      (box
        {:class remark-style}
        (entry
          {:connect_map (fn [entry]
                          (entry:set_text "")
                          (entry:grab_focus))
           :placeholder "Search content/remark here"
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
             ;:hpolicy consts.PolicyType.never
             :size_request [400 0]}
            (list-view
              {
                :data filtered-item
                :show_separators true
                :render (fn [item]
                          (box
                            {:connect_click_release 
                             (fn []
                               (let [index (. (item) :index)]
                                 (execute-paste index)))}
                            (box
                              (map item
                                   (fn [item]
                                     (match item.type
                                       (where :text (is-url item.content)) 
                                       (label {:markup (make-link item.content)
                                               :ellipsize consts.PangoEllipsizeMode.middle
                                               :xalign 0})
                                       :text (label {:label item.sub
                                                     :ellipsize consts.PangoEllipsizeMode.middle
                                                     :xalign 0})
                                       :image (box {:size_request [100 100]
                                                    :orientation consts.Orientation.Horizontal
                                                    :valign consts.Align.Center
                                                    :halign consts.Align.Start
                                                    :vexpand false :hexpand false}
                                                (picture {:texture item.texture}))))))
                            (box
                              {:orientation consts.Orientation.Horizontal}
                              (label {:text (map item 
                                                 #(let [remark (or $1.remark "")]
                                                    (if (not= remark "")
                                                      (.. " " remark)
                                                      remark)))
                                      :class remark-style
                                      :hexpand true
                                      :xalign 0})
                              (icon-button
                                {:name :document-print-preview
                                 :connect_click (fn []
                                                  (let [index (. (item) :_data_index)]
                                                    (selected-index (- index 1))))})
                              (icon-button
                                {:name :edit-clear
                                 :connect_click (fn []
                                                  (clipboard-items
                                                    (list.filter (clipboard-items)
                                                                 #(not= $1 (item))))
                                                  (save-clipboard-items (clipboard-items)))}))))}))
          (detail {:item selected-item
                   :onRemarkUpdate (fn [txt]
                                     (let [item (selected-item)]
                                       (print (inspect item) txt)
                                       (update-remark
                                         item.index
                                         txt)))}))
        (box
          {:orientation consts.Orientation.Horizontal}
          (label {:label (map clipboard-items #(length $1))
                  :expand true
                  :halign consts.Align.End})))))

(local win 
  (run (clipboard-root))) 
    

{:show (fn [client]
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
