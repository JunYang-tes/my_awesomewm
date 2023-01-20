(local {: window
        : notebook
        : page
        : label} (require :gtk.widgets))
(window
  (notebook
    (page {:title (label {:text :First})}
      (label {:text :First-Content}))
    (page {:title (label {:text :Second})}
      (label {:text :Second-Content}))))
