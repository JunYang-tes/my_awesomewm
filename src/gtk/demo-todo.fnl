(local {: Gtk} (require :lgi))
(local {: window
        : scrolled-window
        : label
        : entry
        : button
        : make-children
        : box} (require :gtk.widgets))
(local list (require :utils.list))
(local r (require :gtk.observable))
(local inspect (require :inspect))

(local todos (r.value [
                       (r.value {:title :hello :done false})
                       (r.value {:title :world :done true})]))
(fn new-todo [{: on-new}]
  (let [e (entry {:-expand true
                  :-fill true})]
    (box
      e
      (button 
        {:label :Add
         :on_clicked 
          (fn []
            (on-new e.text)
            (tset e :test nil))}))))
(fn list-item [{: todo}]
  (box
    (label {
            :markup (r.map todo (fn [{: done : title}] 
                                  (if done 
                                      (.. "<strike>" title "</strike>")
                                      title)))})))
            ;; :on_clicked #(todo (let [v (todo)]
            ;;                      {:title v.title
            ;;                       :done (not v.done)}))})))
    
(fn todo-list [{: todos}]
  ;;(scrolled-window)
  (box
    {:orientation Gtk.Orientation.VERTICAL}
    ;; O<[label,label]>
    (r.map todos
      (fn [todos]
        (print :todos-change)
        (list.map todos 
                  ;;#(label {:markup (r.map $1 #(. $1 :title))})
                  #(list-item {:todo $1}))))))


(window
  (box
    {:orientation Gtk.Orientation.VERTICAL}
    (new-todo
      {:on-new #(todos (let [current (todos)]
                         (list.push current (r.value {:title $1
                                                      :done false}))))})
    (todo-list 
      {: todos})))
    
    
    
                         
