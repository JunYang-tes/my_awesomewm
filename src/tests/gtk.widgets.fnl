(import-macros { : mk-test } :test)
(local inspect (require :inspect))
(local test (require :u-test))
(local r (require :gtk.observable))
(local w (require :gtk.widgets))
(local list (require :utils.list))
(local stringx (require :utils.string))

(mk-test
  :gtk.widgets.label
  (let [text (r.of :hello)
        l (w.label {:text text})]
    (test.equal true (w.is-widget l))
    (test.equal :hello (l:get_text))
    (text :world)
    (test.equal :world (l:get_text))
    (test.equal true (. l :visible))))
(mk-test
  :gtk.widgets.button
  (let [b (w.button {:label :hello})]
    (test.equal true (w.is-widget b))))
(mk-test
  :gtk.widgets.box
  (let [b (w.box)]
    (test.equal true (w.is-widget b))))
(mk-test
  :gtk.widgets.window
  (let [win (w.window {:visible false})]
    (test.equal true (w.is-widget win))))

;; (mk-test 
;;   :gtk.widgets.make-children.non-observable
;;   (let [children (w.make-children [1 2 3])]
;;     (test.equal (inspect children) (inspect [1 2 3]))))
;; (mk-test 
;;   :gtk.widgets.make-children.non-observable-nested
;;   (let [children (w.make-children [1 [2 3] 4])]
;;     (test.equal (inspect children) (inspect [1 2 3 4]))))

;; (mk-test 
;;   :gtk.widgets.make-children.non-observable
;;   (let [children (w.make-children [1 2 3])]
;;     (test.equal (inspect children) (inspect [1 2 3]))))

;; (mk-test
;;   :gtk.widgets.make-children.observable-array
;;   (let [a (r.value 0)
;;         b (r.value 1)
;;         c (r.value 2)
;;         children (w.make-children [a b c])]
;;     (test.equal (inspect (children )) (inspect [0 1 2]))
;;     (a 1)
;;     (b 2)
;;     (c 3)
;;     (test.equal (inspect (children )) (inspect [1 2 3]))))

;; (mk-test
;;   :gtk.widgets.make-children.mixed
;;   (let [a (r.value 0)
;;         children (w.make-children [a 1])]
;;     (test.equal (inspect (children )) (inspect [0 1]))
;;     (a 1)
;;     (test.equal (inspect (children )) (inspect [1 1]))))

;; (mk-test
;;   :gtk.widgets.make-children.observable
;;   (let [a (r.value [(r.value :a) (r.value :b)])
;;         b (r.map a (fn [items]
;;                        (list.map items (fn [i] (w.label {:markup i})))))
;;         children (w.make-children b)]
;;     (test.equal (length (children )) 2)
;;     (test.is_true
;;       (list.every (children)
;;                   (fn [child]
;;                     (stringx.starts-with (tostring child) :lgi))))
;;     (a [(r.value :hello)])
;;     (test.equal (length (b)) 1)
;;     (test.equal (length (children )) 1)))
