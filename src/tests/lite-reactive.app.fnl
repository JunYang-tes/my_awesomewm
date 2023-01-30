(import-macros { : mk-test } :test)
(local test (require :u-test))
(local {: run
        : _tests} (require :lite-reactive.app))
(local {: button 
        : box} (require :gtk.node))
(local {: is-widget} (require :gtk.widgets))
(local {: value : map : map-list} (require :lite-reactive.observable))
(local list (require :utils.list))

(mk-test
  :gtk.app.run.atom
  (let [label (value :hello)
        btn (button {: label})
        btn-widget (run btn)]
    (test.equal (is-widget btn-widget) true)
    (test.equal (btn ) btn-widget)
    (test.equal btn-widget.label :hello)
    (label :world)
    (test.equal btn-widget.label :world)))
(mk-test
  :gtk.app.run.container
  (let [label (value :hello)
        b (box
             [(button {: label})])
        r (run b)
        children (r:get_children)
        child (. children 1)]
    (test.equal (is-widget r) true)
    (test.equal (length children) 1)
    (test.equal child.label :hello)
    (label :world)
    (test.equal child.label :world)))
    

(mk-test
  :gtk.app.run.container.box.relayout
  (let [label (value :hello)
        expand (value true)
        b (box {}
              [(button {: label
                        :-expand expand})])
        r (run b)
        children (r:get_children)
        child (. children 1)]
    (let [(expand) (r:query_child_packing child)]
      (test.equal expand true))
    (expand false)
    (let [(expand) (r:query_child_packing child)]
      (test.equal expand false))))
(mk-test
  :gtk.app.run.container.box.children
  (let [data (value [:a :b])
        expand (value true)
        b (box
            (map-list data
             #(button {:label $1})))
            ;; (map data 
            ;;      (fn [items]
            ;;        (list.map items 
            ;;                  (fn [item]
            ;;                    (print :ddd
            ;;                     (button {:label item})))))))]
        r (run b)
        children (r:get_children)]
    (test.equal (length children ) 2)
    (test.equal (. children 1 :label) :a)
    (data [:c :d :e])
    (let [children (r:get_children)]
      (test.equal (length children) 3)
      (test.equal (. children 1 :label) :c))))
(mk-test
  :lite-reactive.app.difference
  (test.equal
    (table.concat
      (_tests.difference [:a :b ] [:a :b :c :d]))
    (table.concat [:c :d])))
