(import-macros { : mk-test } :test)
(local nodes (require :gtk.node))
(local test (require :u-test))
(local {: value} (require :lite-reactive.observable))
(local {: run} (require :lite-reactive.app))
(import-macros { : defn } :lite-reactive)

(mk-test
  :gtk.node.button
  (let [l (value :hello)
        b (nodes.button {:label l})]
    (test.not_equal b.build nil)
    (test.equal b.type :atom)))

(mk-test
  :gtk.node.box
  (let [box (nodes.box {} [])
        box1 (nodes.box)
        box2 (nodes.box (nodes.button))
        children box2.children]
    (test.equal box.type :container)
    (test.equal box1.type :container)
    (test.equal (length children) 1)))
(mk-test
  :gtk.node.custom
  (defn custom-node 
        (nodes.button {:label props.hello}))
  (let [r (run (custom-node :hello))]
    (test.equal r.label :hello)
    (print r)))
