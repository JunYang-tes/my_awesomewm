(local {: run } (require :lite-reactive.app))
(local {: window
        : notebook
        : label} (require :gtk.node))
(run
  (window
    (notebook
      (label {
              :-title (label {:text :First})
              :text :First-Content})
      (label {
              :-title (label {:text :Second})
              :text :Second-Content}))))
