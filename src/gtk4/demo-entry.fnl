(local {: window
        : label
        : box
        : entry} (require :gtk4.node))
(local {: run } (require :lite-reactive.app))

(local r (require :lite-reactive.observable))
(local text (r.value ""))
(run (window 
      (box
        {:orientation 1
         :halign 3
         :valign 3}
        (entry {:text text
                :connect_key_press_event #(do
                                            (print :key_press_event $1)
                                            (text.set (: $1 :text)))})
        (entry {:text text :connect_key_press_event #(text.set (: $1 :text))})
        (label {:text (r.map text #(.. "length:" (length $1)))}))))

