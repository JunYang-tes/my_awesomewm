(import-macros {: unmount : defn : effect} :lite-reactive)
(local {: Gtk } (require :lgi))
(local {: window
        : label
        : line_edit
        : vbox
        : list
        : list-row
        : button} (require :qt.node))
(local {: run } (require :lite-reactive.app))
(local list-utils (require :utils.list))
(local r (require :lite-reactive.observable))
(import-macros { : time-it } :utils)
(local consts (require :gtk_.const))
(local item-count (r.value 1000))
(local data 
            (->
              (list-utils.range 0 1000)
              (list-utils.map (fn [i]
                                  (.. "Item " i)))))
(local stringx (require :utils.string))
(local {: read-popen} (require :utils.process))
(local {: basename } (require :utils.path))



(local path (let [(ok? path) (pcall
                               #(with-open [in (io.open
                                                 (.. (os.getenv :AWESOME_CONFIG)
                                                     "/config/bookmarks"))]
                                          (icollect [i v (in:lines)]
                                                    i)))]
              (if ok?
                path
                [])))

(fn ignore []
  (let [ignore [:.git
                :node_modules]]
    (-> ignore
        (list-utils.map #(.. " -not -path '*/" $1 "/*'"))
        table.concat)))

(fn find [path]
  (-> path
      (list-utils.map (fn [p]
                        (read-popen
                          (.. "find " p
                              " -type f "
                              (ignore)))))
      (list-utils.flatten)))

(local data (find path))
(local filter (r.value ""))
(local filtered (r.value data))

; (defn ListItem
;   (list-row
;     (box
;       {:orientation Gtk.Orientation.VERTICAL}
;       (label 
;         {:markup (r.map props.path #"test")
;          :xalign 0})
;       (label
;         {:label (r.map props.path (fn [p]
;                                     (.. "??" p)))
;          :wrap true
;          :xalign 0}))))
; (defn ListItem1
;   (label
;     {:label (r.map props.path (fn [p]
;                                 (.. "??" p)))
;      :wrap true
;      :xalign 0}))


(defn App
  (effect [filter]
          (filtered 
            (-> data
                (list-utils.filter (fn [item]
                                     (stringx.includes item (filter)))))))
  (window
    (vbox
      (label {:text (r.map filtered (fn [items]
                                      (.. (length items)
                                          " items")))})
      (line_edit
        {
         :on_text_edited (fn [w]
                           (print w)
                          (filter (w:text)))})
      (list
        (r.map filtered
               (fn [items]
                 (-> items
                     (list-utils.map #(label {:text $1})))))))))
      ; (scrolled-window
      ;   {:vexpand true}
      ;   (list-box
      ;     (r.map filtered
      ;            (fn [items]
      ;              (-> items
      ;                  (list.map #(ListItem1 {:path $1}))))))))))
      ;
(run (App))
