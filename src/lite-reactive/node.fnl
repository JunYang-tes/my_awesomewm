(local {: assign } (require :utils.table))
(local observable (require :lite-reactive.observable))
(local inspect (require :inspect))
(local list (require :utils.list))


(fn is-node [obj]
  (and (= (type obj) :table)
    (let [t obj.type]
      (or (= t :atom)
          (= t :container)
          (= t :custom)))))
(fn is-props-table [obj]
  (and (= (type obj) :table)
       (not (list.is-list obj))
       (not (is-node obj))
       (not (observable.is-observable obj))))

(fn make-children [child]
  (let [children (list.flatten (if (list.is-list child ) child [child]))]
    (if (list.some children #(observable.is-observable $1))
        (let [observables (list.map children observable.of)
              r (observable.value (->  observables
                                       observable.flat-collect
                                       (list.filter #$1)))]
          (observable.observe-list-deep
            observables (fn [] 
                          (-> observables
                              observable.flat-collect
                              (list.filter #$1)
                              r)))
                          ;; (r (observable.flat-collect observables))))
          r)
        children)))
;; accepted forms:
;; 1 argment:
;;  props | child[] | child
;; 2 argments:
;; [props child] | [props child[]] | child child
;; varargs:
;; [props-or-child ...]
(fn prepare-props [...]
  (let [all [...]]
    (if 
      (= (length all) 1)
      (let [[first] all] 
        (if (is-props-table first)
          [first []]
          [{} (make-children first)]))
      (= (length all ) 2)
      (let [[props children] all]
        (if (is-props-table props)
            [props (make-children children)]
            [{} (make-children all)]))
      (let [[first & others] all]
        (if (is-props-table first)
          (if (> (length others) 0)
            [first (make-children others)]
            [first []])
          [{} (make-children all)])))))


(fn atom-node [build]
  (fn [props]
    {:type :atom
     : build
     :props (or props {})}))

(fn container-node [build update-children relayout]
  (fn [...]
    (let [[props children] (prepare-props ...)]
      {:type :container
       : build
       : update-children
       : relayout
       : props
       : children})))

(fn custom-node [build]
  (fn [...]
    (let [[props children] (prepare-props ...)]
      {:type :custom
       : build
       :props (collect [k v (pairs (or props {}))]
                k (observable.of v))
       : children})))

{ : atom-node
  : container-node
  : custom-node
  :_tests { 
           : prepare-props
           : is-props-table}}
