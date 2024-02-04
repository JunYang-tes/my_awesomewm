(import-macros {: defn
                : unmount } :lite-reactive)
(import-macros {: catch} :utils)
(local {: inspect-node } (require :lite-reactive.node))
(local {: gtk} (require :widgets))
(local {: box
        : label
        : entry
        : button
        : check-button
        : window} (require :gtk_.node))
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
(defn show_
  (map props.show
       #(if $1 (props.child) nil)))
(defn app
  (unmount
    (print :app-unmounted))
  (local win nil)
  (let [show (value true)
        text (value :world)
        win (window
              ;; { :keepAlive false}
               ;; :on_delete_event
               ;;  (fn []
               ;;    (print :delete)
               ;;    true)}
              (box
                { :orientation 1}
                (entry {:text text
                        :connect_key_release_event #(text (: $1 :text))})
                (button
                  {:label :Close
                   :connect_clicked (fn []
                                      (print :will-close (win))
                                      (let [w (win)]
                                       (w:close)))})
                (button
                  {:label (map show #(if $1 "Hide " "Show "))
                   :connect_clicked #(show (not (show)))})
                (show_ {: show
                        :child (my-component {:text text})})
                ; (map show
                ;   #(if $1
                ;        (my-component {:text text})
                ;       false))
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
