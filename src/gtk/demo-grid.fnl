(local {: Gtk
        : Gdk} (require :lgi))
(local {: window
        : grid
        : grid-item
        : button} (require :gtk.widgets))
(window
  (grid
      (button {:hexpand true :label :button1 :-left 0 :-top 0 :-width 1 :-height 1})
      (button {:hexpand true :label :button2 :-left 1 :-top 0 :-width 2 :-height 1})
      (button {:halign Gtk.Align.CENTER :label :button3 :-left 0 :-top 1 :-width 1 :-height 2})
      (button {:label :button4 :-left 1 :-top 1 :-width 2 :-height 1})
      (button {:label :button5 :-left 1 :-top 2 :-width 1 :-height 1})
      (button {:label :button4 :-left 2 :-top 2 :-width 1 :-height 1})))
