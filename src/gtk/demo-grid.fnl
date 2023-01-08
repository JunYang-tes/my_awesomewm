(local {: Gtk
        : Gdk} (require :lgi))
(local {: window
        : grid
        : grid-item
        : button} (require :gtk.widgets))
(window
  {:window_type Gtk.Window.POPUP
   :role :dialog
   :type_hint Gdk.WindowTypeHint.DIALOG}
  (grid
    [(grid-item
       {:left 0 :top 0 :width 1 :height 1}
       (button {:label :button1}))
     (grid-item
       {:left 1 :top 0 :width 2 :height 1}
       (button {:label :button2}))
     (grid-item
       {:left 0 :top 1 :width 1 :height 2}
       (button {:label :button3}))
     (grid-item
       {:left 1 :top 1 :width 2 :height 1}
       (button {:label :button4}))
     (grid-item
       {:left 1 :top 2 :width 1 :height 1}
       (button {:label :button5}))
     (grid-item
       {:left 2 :top 2 :width 1 :height 1}
       (button {:label :button4}))]))
