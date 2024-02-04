(local {: Gtk : Gdk} (require :lgi))
(local {: run } (require :lite-reactive.app))
(local {: window
        : label
        : box
        : check-button
        : button} (require :gtk.node))
(local list (require :utils.list))
(local r (require :lite-reactive.observable))
(local btn1-expand (r.value true))
(local btn1-fill (r.value true))
(local btn2-expand (r.value true))
(local btn2-fill (r.value true))
(local btn3-expand (r.value true))
(local btn3-fill (r.value true))
(local homegeneous (r.value true))
(local dialog (r.value true))

(fn box-item-setting [expand fill]
  (print expand fill)
  [ 
    (check-button
      { :label "Expand"
        :active expand
        :on_toggled #(expand $1.active)})
    (check-button
      { :label "Fill"
        :active fill
        :on_toggled #(fill $1.active)})])
(run
       (window
         { :type_hint (r.map dialog #(if $1 Gdk.WindowTypeHint.DIALOG Gdk.WindowTypeHint.NORMAL))}
         (box
           {:orientation Gtk.Orientation.VERTICAL
            :valign Gtk.Align.CENTER}
           (box
             (box-item-setting btn1-expand btn1-fill)
             (box-item-setting btn2-expand btn2-fill)
             (box-item-setting btn3-expand btn3-fill)
             (check-button
               {:label :Homegeneous
                :active homegeneous
                :on_toggled #(homegeneous (. $1 :active))})
             (check-button 
               {:label :dialog
                :active dialog
                :on_toggled #(dialog (. $1.active))}))
           (box
             ;{: homogeneous}
             (button {:label :button1
                      :-expand btn1-expand
                      :-fill btn1-fill})
             (button {:label "This is button2"
                      :-expand btn2-expand
                      :-fill btn2-fill})
             (button {:label :button3
                      :-expand btn3-expand
                      :-fill btn3-fill})))))

