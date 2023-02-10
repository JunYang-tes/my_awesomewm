(import-macros {: defn : effect : unmount} :lite-reactive)
(import-macros {: catch} :utils)
(local {: Gdk} (require :lgi))
(local {: window
        : button
        : menu-button
        : label
        : box
        : popover} (require :gtk.node))
(local {: run : use-run} (require :lite-reactive.app))
(local w (require :gtk.widgets))
(local o (require :lite-reactive.observable))

(defn app
  (let [show (o.value false)
        btn (button {:label (o.map show #(if $1 :Hide :Show))
                     :on_clicked 
                     (fn []
                        (show (not (show))))})]
          
      ;; (if (show)
      ;;   (let [s (show)
      ;;         b (mbtn)
      ;;         p (w.popover {:relative_to b})]
      ;;     (print ::!!!!!!!!)
      ;;     (print b)
      ;;     (print p)
      ;;     (p:set_relative_to b)
      ;;     ;(tset p :child (run-it (label {:text :Helloooooooooo})))
      ;;     (print
      ;;       ::popup
      ;;       (p:popup)) 
      ;;     (print ::::END))))
             
    (window
      {
       :title :popover-demo
       :type_hint Gdk.WindowTypeHint.DIALOG}
      (box
        (popover
          {:visible show
           :relative_to btn}
          (button {:label :Hello}))
        btn))))
        
      ;; (flow-box
      ;;   btn
      ;;   (popover
      ;;     {:visible show}
      ;;     (label {:text "Hello World"}))))))
(catch "" ""
  (run
    (app)))
