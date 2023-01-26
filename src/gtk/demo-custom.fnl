(import-macros {: defn
                : unmount } :lite-reactive)
(import-macros {: catch} :utils)
(local {: inspect-node } (require :lite-reactive.node))
(local {: Gtk} (require :lgi))
(local {: box
        : label
        : entry
        : button
        : check-button
        : window} (require :gtk.node))
(local {: run}
       (require :lite-reactive.app))
(local {: value : map : get } (require :lite-reactive.observable))
(local inspect (require :inspect))
(local {: set-timeout} (require :utils.timer))
(local awesome-global (require :awesome-global))

(fn can-call-unmount []
  (unmount (print :UNMOUNTED!)))
(defn my-component
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
(defn app
  (unmount
    (print :app-unmounted))
  (let [show (value true)
        text (value :world)
        win (window
              ;; { :keepAlive false}
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
                                 (let [w (win)]
                                  (w:close)))})
                (button
                  {:label (map show #(if $1 "Hide " "Show "))
                   :on_clicked #(show (not (show)))})
                (map show
                  #(if $1
                       (my-component {:text text})
                      false))
                (label {:label "END"})))]
    win))
        
        
(let [root (app)]
  (run root)
  ;; (print root.build-result)
  ;; (print (length (get root.children)))
  ;;(print (inspect root))
  (print :-------------)
  (catch "" ""
    (print (inspect-node root))))
