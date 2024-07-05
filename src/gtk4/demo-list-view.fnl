(import-macros {: unmount : defn : effect} :lite-reactive)
(local gtk (require :libgtk-lua))
(local {: window
        : scrolled-window
        : label
        : entry
        : box
        : list-box
        : list-view
        : picture
        : list-row
        : button} (require :gtk4.node))
(local {: run } (require :lite-reactive.app))
(local list (require :utils.list))
(local r (require :lite-reactive.observable))
(local consts (require :gtk_.const))
(local {: read-popen} (require :utils.process))
(local stringx (require :utils.string))
(local {: value
        : map-list
        : map
        : mapn} (require :lite-reactive.observable))
(local profile (require :ProFi))


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
        (list.map #(.. " -not -path '*/" $1 "/*'"))
        table.concat)))

(fn find [path]
  (-> path
      (list.map (fn [p]
                  (read-popen
                    (.. "find " p
                        " -type f "
                        (ignore)))))
      (list.flatten)))

(local data 
  (->
    (find path)
    (list.map #{:label :XXXX
                :description $1})))
(local filter (r.value ""))
(local filtered
  (r.map filter
         (fn [filter] 
           (list.filter data #true)))) 
                        ; (fn [i] (stringx.includes i.description filter))))))
           
(local app (gtk.app))

(run (window
       (box
        {:orientation consts.Orientation.VERTICAL}
        (entry
          {
           :connect_change (fn [w]
                             (print :change w)
                             (filter w))})
        (label {:text filter})
        (label {:text (map filtered #(length $1))})
        (button {:label "Start profile"
                 :connect_click (fn []
                                  (profile:start))})
        (button {:label "Stop profile"
                 :connect_click (fn []
                                  (profile:stop)
                                  (profile:writeReport "/tmp/a.txt"))})
        (scrolled-window
          {:vexpand true}
          (list-view
            {
             :data filtered
             :render (fn [cmd]
                       (box 
                         {:spacing 0
                          :orientation consts.Orientation.Horizontal}
                          ; :class (mapn [cmd (value 0)] 
                          ;              (fn [[cmd selected]]
                          ;                (.. "cmd-item "
                          ;                    (if (= cmd._data_index
                          ;                           selected)
                          ;                      "selected "
                          ;                      ""))))}
                         ; (box 
                         ;   {:size_request (map cmd 
                         ;                                 #(if (not= nil $1.image)
                         ;                                    [36 36]
                         ;                                    [0 0])) 
                         ;    :class "image"
                         ;    :vexpand false :hexpand false
                         ;    :valign consts.Align.Center
                         ;    :halign consts.Align.Start}
                         ;   (picture {:texture (map cmd #$1.image)
                         ;             :vexpand false
                         ;             :hexpand false
                         ;             :content_fit 0}))
                         (box 
                           {:spacing 0
                            :class "labels"
                            :valign consts.Align.Center}
                           (label
                             {;:markup (map cmd #$1.label)
                              :markup filter
                              :class :cmd-label
                              ; :hexpand true
                              ; :wrap true
                              :xalign 0})
                           (let [desc (mapn [cmd (value "")]
                                            (fn [[cmd input]]
                                              (if cmd.real-time
                                                "real time"
                                                (or cmd.description "(No description)"))))]
                             (label
                               {:label desc
                                ;:markup filter
                                :class "cmd-desc"
                                ; :wrap true
                                ; :wrap_mode consts.WrapMode.Char
                                :xalign 0})))))})))))

(lua "while(true) do app:iteration(true);  end")
