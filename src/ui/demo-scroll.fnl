(local {: run } (require :lite-reactive.app))
(local {: value
        : map} (require :lite-reactive.observable))
(local wibox (require :wibox))
(local inspect (require :inspect))
(local {: popup
        : scrollview
        : textbox
        : v-fixed
        : background} (require :ui.node))

(run
  (popup
    (v-fixed
      (textbox {:markup :START})
      (scrollview
        {:forced_width 200
         :forced_height 200}
        (background
          {:bg :#ff0000
           :forced_width 150}
          (v-fixed
            (textbox {:markup :Hello1})
            (textbox {:markup :Hello2})
            (textbox {:markup :Hello3})
            (textbox {:markup :Hello4})
            (textbox {:markup :Hello5})
            (textbox {:markup :Hello6})
            (textbox {:markup :Hello7})
            (textbox {:markup :Hello8})
            (textbox {:markup :Hello9})
            (textbox {:markup :Hello10})
            (textbox {:markup :Hello11})
            (textbox {:markup :Hello12})
            (textbox {:markup :Hello13})
            (textbox {:markup :Hello14})
            (textbox {:markup :Hello15})
            (textbox {:markup :Hello16})
            (textbox {:markup :Hello17})
            (textbox {:markup :Hello18})
            (textbox {:markup :Hello19}))))
      (textbox {:markup :END}))))

