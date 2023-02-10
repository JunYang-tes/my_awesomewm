(import-macros {: defn
                : unmount } :lite-reactive)
(import-macros {: catch } :utils)
(local {: Gtk } (require :lgi))
(local {: window
        : scrolled-window
        : label
        : entry
        : button
        : check-button
        : make-children
        : event-box
        : box} (require :gtk.node))
(local {: is-enter-event } :gtk)
(local list (require :utils.list))
(local r (require :lite-reactive.observable))
(local inspect (require :inspect))
(local {: run
        : foreach } (require :lite-reactive.app))
(local todos (r.value [
                       (r.value {:title :hello :done false})
                       (r.value {:title :world :done true})]))
(defn new-todo
  (let [
        on-new props.on-new
        emit-on-new (fn [entry]
                      (when (> (length entry.text) 0)
                          ((on-new) entry.text)
                          (tset entry :text "")))
        e (entry {:-expand true
                  :-fill true
                  :on_key_release_event (fn [widget event]
                                          (if (= event.keyval
                                                 65293)
                                              (emit-on-new (e))))})]
    (box
      e
      (button 
        {:label :Add
         :on_clicked 
          (fn []
            (emit-on-new (e)))}))))

(defn list-item
  (local {: todo : on-delete} props)
  (unmount
    (print :unmount-list-item))
  (box
    (check-button
      {
        :active (r.pick todo :done)
        :on_toggled #(todo 
                       (let [curr (todo)]
                          {:title curr.title
                           :done $1.active}))})
      
    (event-box
      {:on_button_press_event #(todo 
                                 (let [curr (todo)]
                                  {:title curr.title
                                   :done (not curr.done)}))}
      (label {
              :hexpand true
              :-fill true
              :halign Gtk.Align.LEFT
              :markup (r.map todo (fn [{: done : title}] 
                                    (if done 
                                        (.. "<s>" title "</s>")
                                        title)))}))
    (button
      {:label :Delete
       :on_clicked on-delete})))
            ;; :on_clicked #(todo (let [v (todo)]
            ;;                      {:title v.title
            ;;                       :done (not v.done)}))})))
    
(defn todo-list
  (local {: todos} props)
  (scrolled-window
    {:-expand true
     :-fill true}
    (box
      {:orientation Gtk.Orientation.VERTICAL}
      (catch "foreach failed" (label {:text :ERROR})
        (foreach todos
                 (fn [item]
                   (list-item
                     {:todo item
                      :on-delete #(todos
                                    (let [curr (todos)]
                                      (list.filter curr #(not= $1 item))))})))))))
      ;;-------------------

      ;; (r.map-list todos
      ;;   (fn [item]
      ;;     (list-item 
      ;;       {:todo item
      ;;        :on-delete #(todos
      ;;                      (let [curr (todos)]
      ;;                        (print :!!!!!!-delete)
      ;;                        (list.filter curr #(not= $1 item))))}))))))
      ;;;;;
      ;; O<[label,label]>
      ;; (foreach todos
      ;;   (fn [item]
      ;;     (list-item {:todo item
      ;;                 :on-delete #(todos 
      ;;                               (let [curr (todos)]
      ;;                                 (list.filter curr #(not= $1 item))))}))))))
      ;; (r.map todos
      ;;   (fn [todos]
      ;;     (print :todos-change)
      ;;     (list.map todos 
      ;;               ;;#(label {:markup (r.map $1 #(. $1 :title))})
      ;;               #(list-item {:todo $1})))))))


(run
  (window
    (box
      {:orientation Gtk.Orientation.VERTICAL}
      (new-todo
        {:on-new #(todos (let [current (todos)]
                           (list.push current (r.value {:title $1
                                                        :done false}))))})
      (todo-list 
        {: todos}))))
