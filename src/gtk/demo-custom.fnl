(import-macros {: defc
                : unmount } :lite-reactive)
(local {: Gtk} (require :lgi))
(local {: box
        : label
        : entry
        : button
        : check-button
        : window} (require :gtk.node))
(local {: run}
       (require :lite-reactive.app))
(local {: value : map } (require :lite-reactive.observable))
(local inspect (require :inspect))
(local {: set-timeout} (require :utils.timer))
(local awesome-global (require :awesome-global))

(fn can-call-unmount []
  (unmount (print :UNMOUNTED!)))
(defc my-component
      (print :run-my-component)
      (unmount
        (print :this) 
        (print :is)
        (print :unmounted))
      (can-call-unmount)
      (box
        {:spacing 10}
        (label {:text :hello})
        (label {:text props.text})))
(defc app
  (let [show (value false)
        text (value :world)
        w (my-component {:text text})
        win (window
              {:on_destroy 
                (fn []
                  (print :destroy)
                  false)}
               ;; :on_delete_event
               ;;  (fn []
               ;;    (print :delete)
               ;;    true)}
              (box 
                { :orientation Gtk.Orientation.VERTICAL}
                (entry {:text text
                        :on_key_release_event #(text $1.text)})
                (button
                  {:label :Close
                   :on_clicked (fn [] 
                                 (print :will-close (win))
                                 (-> (win) 
                                     (: :close)))})
                (button
                  {:label (map show #(if $1 "Hide " "Show "))
                   :on_clicked #(show (not (show)))})
                (map show
                  #(if $1 
                       w
                      false))
                (label {:label "END"})))]
    win))
        
        
(run (app))
