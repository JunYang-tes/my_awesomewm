(local {: window
        : scrolled-window
        : label
        : box
        : list-box
        : list-row
        : check-button
        : button} (require :gtk_.node))
(local {: run } (require :lite-reactive.app))
(run
  (window
    (list-box
      (label {:label :??})
      (list-row
        (label {:label :Hello}))
      (list-row
        (label {:label :World}))
      (label {:label :??}))))
