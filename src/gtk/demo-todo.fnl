(import-macros {: <- } :assign)
(local {: Gtk } (require :lgi))
(local {: window
        : scrolled-window
        : label
        : entry
        : button
        : check-button
        : make-children
        : foreach
        : box} (require :gtk.widgets))
(local list (require :utils.list))
(local r (require :gtk.observable))
(local inspect (require :inspect))

(local todos (r.value [
                       (r.value {:title :hello :done false})
                       (r.value {:title :world :done true})]))
(fn new-todo [{: on-new}]
  (let [
        on-new (r.of on-new)
        emit-on-new (fn [entry]
                      (when (> (length entry.text) 0)
                          ((on-new) entry.text)
                          (tset entry :text "")))
        e (entry {:-expand true
                  :-fill true
                  :on_key_release_event (fn [widget event]
                                          (if (= event.keyval
                                                 65293)
                                              (emit-on-new e)))})]
    (box
      e
      (button 
        {:label :Add
         :on_clicked 
          (fn []
            (emit-on-new e))}))))

(fn list-item [{: todo : on-delete}]
  (print :build-new-list-item)
  (box
    (check-button
      {
        :active (r.pick todo :done)
        :on_toggled #(todo 
                       (let [curr (todo)]
                          {:title curr.title
                           :done (not curr.done)}))})
      
    (label {
            :hexpand true
            :fill true
            :halign Gtk.Align.LEFT
            :markup (r.map todo (fn [{: done : title}] 
                                  (if done 
                                      (.. "<s>" title "</s>")
                                      title)))})
    (button
      {:label :Delete
       :on_clicked on-delete})))
            ;; :on_clicked #(todo (let [v (todo)]
            ;;                      {:title v.title
            ;;                       :done (not v.done)}))})))
    
(fn todo-list [{: todos}]
  (scrolled-window
    {:-expand true
     :-fill true}
    (box
      {:orientation Gtk.Orientation.VERTICAL}
      ;; O<[label,label]>
      (foreach todos
        (fn [item]
          (list-item {:todo item
                      :on-delete #(todos 
                                    (let [curr (todos)]
                                      (list.filter curr #(not= $1 item))))}))))))
      ;; (r.map todos
      ;;   (fn [todos]
      ;;     (print :todos-change)
      ;;     (list.map todos 
      ;;               ;;#(label {:markup (r.map $1 #(. $1 :title))})
      ;;               #(list-item {:todo $1})))))))


(window
  (box
    {:orientation Gtk.Orientation.VERTICAL}
    (new-todo
      {:on-new #(todos (let [current (todos)]
                         (list.push current (r.value {:title $1
                                                      :done false}))))})
    (todo-list 
      {: todos})))
    
    
    
                         
