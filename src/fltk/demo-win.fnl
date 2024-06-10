(local {: window
        : flex
        : scroll
        : pack
        : button} (require :fltk.node))
(local {: run } (require :lite-reactive.app))

; (print (run (button {:label :hello})))
; (let [win
;       (run (window
;              (flex
;                {:frame 2
;                 :size [100 100]
;                 :pos [100 100]}
;                (button
;                  {:label "Hello"
;                   :pos [10 10]})
;                (button
;                  {:label "World"})
;                (button
;                  {:label "World"}))))]
;   (win:show))

(run (window
       (scroll {:pos [100 100]
                :label "scroll"
                :size [100 100]}
        (pack
          {:pos [0 0]}
          (button {:label "Hello"
                   :size [100 10]})
          (button {:label "World"
                   :size [100 10]})
                   
          (button {:label "World"
                   :size [100 10]})
          (button {:label "World"
                   :size [100 10]})
          (button {:label "World"
                   :size [100 10]})
          (button {:label "World"
                   :size [100 10]})
          (button {:label "World"
                   :size [100 10]})
          (button {:label "World"
                   :size [100 10]})
          (button {:label "World"
                   :size [100 10]})))))
