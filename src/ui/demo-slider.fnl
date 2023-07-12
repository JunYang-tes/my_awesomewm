(import-macros { : effect} :lite-reactive)
(local {: run } (require :lite-reactive.app))
(local {: value
        : map} (require :lite-reactive.observable))
(local wibox (require :wibox))
(local inspect (require :inspect))
(local {: popup
        : slider
        : v-fixed
        : background} (require :ui.node))

(let [cnt (value 50)]
  (run
    (popup
      (v-fixed
        (slider
          {:forced_width 200
           :value cnt
           :maximum 100
           :minimum 0
           :onValueChange (fn [slider]
                            (cnt slider.value))
           :forced_height 20})
        (slider
          {:forced_width 200
           :value cnt
           :maximum 100
           :minimum 0
           :onValueChange (fn [slider]
                            (cnt slider.value))
           :forced_height 20})))))

