(import-macros {: unmount : defn : effect} :lite-reactive)
(import-macros {: time-it} :utils)
(import-macros {: css-gen } :css)
(import-macros {: global-css : css } :gtk)
(local {: Gtk} (require :lgi))
(local profiler (require :ELProfiler))
(local {: value
        : map-list
        : map
        : mapn} (require :lite-reactive.observable))
(local {: window
        : box
        : label
        : list-box
        : scrolled-window
        : entry} (require :gtk.node))
(local list (require :utils.list))
(local {: run
        : foreach} (require :lite-reactive.app))

(profiler.start)
(time-it :RUN
  (run
    (window
      (box
        {:orientation Gtk.Orientation.VERTICAL}
        (scrolled-window
          {:-expand true
                   ;:class (css [:min-height :400px])
                   :-fill true}
          (list-box
            (-> (list.range 0 2000 1)
                (list.map
                  (fn []
                    (box
                      {:orientation Gtk.Orientation.VERTICAL}
                                 ; :class (css [:border-bottom "1px solid #ccc"
                                 ;              :padding-left :8px])}
                      (label
                        {:markup "HELLO"})
                      (label 
                        {:markup "WORLD"})))))))))))
(print (profiler.format (profiler.stop)))
