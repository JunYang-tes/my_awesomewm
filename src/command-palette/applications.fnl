(local {: xdgkit } (require :widgets))
(local gtk (require :libgtk-lua))
(local {: read-popen} (require :utils.process))
(local list (require :utils.list))
(local str-fns (require :utils.string))
(local search-path
  [:/usr/share/applications/
   (.. (os.getenv :HOME) :/.local/share/applications)])
(local inspect (require :inspect))
(local awful (require :awful))
(local {: every-idle } (require :utils.wm))
(local {: timer} (require :gears))
(local {: get-codebase-dir} (require :utils.utils))

(local apps
  (let [def-icon (gtk.texture_from_file (.. (get-codebase-dir) "/icons/executable.svg"))
        load (fn []
              (-> search-path
                  xdgkit.load_desktop_entries
                  (list.map (fn [app]
                              {:label (-> [app.name app.generic_name (table.concat app.keywords " ")]
                                        (list.filter #(not= $1 ""))
                                        (table.concat "/"))
                               :_icon app.icon_name
                               :exec (fn []
                                       (awful.spawn
                                         (.. "gtk-launch " app.filename)))}))))]

    (var cache (load))
    (var index 1)
    (fn set_icon []
      (let [item (. cache index)
            icon (if (str-fns.starts-with item._icon "/")
                   item._icon
                   (xdgkit.find_icon item._icon))]
        (if (not= icon "")
          (tset item :image (gtk.texture_from_file icon))
          (tset item :image def-icon)))
      (set index (+ index 1))
      (when (< index (length cache))
        (timer.delayed_call
          set_icon)))
    (timer.delayed_call
      set_icon)

    {:get (fn [] cache)
     :reload (fn []
               (set cache (load)))}))

{:applications {:label :Applications
                :exec apps.get}
 :reload-apps {:label "Reload application"
               :exec apps.reload}}
