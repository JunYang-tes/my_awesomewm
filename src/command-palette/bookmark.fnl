(import-macros {: time-it} :utils)
(local {: read-popen} (require :utils.process))
(local list (require :utils.list))
(local inspect (require :inspect))
(local awful (require :awful))
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

{:open {
        :label :open
        :exec (fn []
                (-> path
                    find
                    (list.map (fn [file]
                                {:label (basename file)
                                 :description file
                                 :exec #(awful.spawn
                                           (string.format "xdg-open '%s'" file))}))))}}

