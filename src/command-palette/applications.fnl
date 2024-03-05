(local {: read-popen} (require :utils.process))
(local list (require :utils.list))
(local str-fns (require :utils.string))
(local search-path
  [:/usr/share/applications/])
(local inspect (require :inspect))
(local awful (require :awful))


(fn parse-desktop [path]
  (let [content (-> (read-popen (.. "cat " path)))
        name (list.find content #(str-fns.starts-with $1 "Name="))
        comment_ (list.find content #(str-fns.starts-with $1 "Comment="))]
    (if name
      {:name (. (str-fns.split name "=") 2)
       :comment (if comment_
                  (. (str-fns.split name "=") 2)
                  "")
       :basename (. (read-popen (.. "basename " path)) 1)
       :file path}
      nil)))

(fn load-applications [path]
  (fn load [path]
    (->
      (read-popen (.. "ls -1 " path))
      (list.filter #(str-fns.ends-with $1 ".desktop"))
      (list.map #(.. path $1))))
  (-> path
     (list.map load)
     list.flatten))

(local apps
  (let [load (fn []
              (-> search-path
                  load-applications
                  (list.map parse-desktop)
                  (list.filter #(not= nil $1))
                  (list.map (fn [app]
                              {:label (. app :name)
                               :exec (fn []
                                       (awful.spawn
                                         (.. "gtk-launch " app.basename)))}))))]

    (var cache (load))
    {:get (fn [] cache)
     :reload (fn []
               (set cache (load)))}))

{:applications {:label :Applications
                :exec apps.get}
 :reload-apps {:label "ReloadApplication"
               :exec apps.reload}}
