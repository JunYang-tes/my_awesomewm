(import-macros {: catch } :utils)
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
                              r.set)))
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


(fn atom-node [build name]
  (fn [props]
    {:type :atom
     : build
     : name
     :props (or props {})}))

(fn container-node [build update-children relayout name]
  (fn [...]
    (let [[props children] (prepare-props ...)]
      {:type :container
       : build
       : update-children
       : relayout
       : props
       : name
       : children})))

(fn custom-node [build name]
  (fn [...]
    (let [[props children] (prepare-props ...)]
      {:type :custom
       : build
       : name
       :props (collect [k v (pairs (or props {}))]
                k (observable.of v))
       : children})))

(fn clean [node]
  (let [disposeable (. node :disposeable)]
    (if disposeable
      (each [_ f (ipairs disposeable)]
        (catch "" nil (f))))))


(fn padding-left [str len char]
  (let [padding []]
    (for [i 0 len 1]
      (table.insert padding char))
    (.. (table.concat padding)
        str)))
(fn lines [indent ...]
  (let [r []]
    (each [_ a (ipairs [...])]
      (if (= (type a) :string)
        (table.insert r (padding-left a indent " "))
        (list.is-list a) (each [_ line (ipairs a)]
                           (if (not= nil line)
                             (table.insert r (padding-left line indent " "))))))
    (table.concat r "\n")))

(fn inspect-node [node indent]
  (let [indent (or indent 0)]
    (lines 
      indent
      [
       "{"
       (.. "name=" (or node.name :no-name))
       (.. "type=" node.type)
       (.. "disposeable=" (if (. node.disposeable)
                              (.. "<" (length node.disposeable) ">")
                              :nil))
       (if (and 
             (= :custom node.type)
             (length node.build-result))
           (lines
             indent
             "build-result=["
              (icollect [_ v (ipairs (or node.build-result []))]   
                (inspect-node v (+ indent 2)))
             "]"))
       (if (length (or (observable.get node.children) []))
           (lines
             indent
             "children=["
                (icollect [_ v (ipairs (or (observable.get node.children) []))]
                  (inspect-node v (+ indent 2)))
             "]"))
       "}"])))
    
(fn destroy [node]
  (tset node :parent nil)
  (clean node)
  (if (= :custom node.type)
    (each [_ n (ipairs (or node.build-result []))]
      (destroy n))
    (each [_ n (ipairs (or (observable.get node.children)
                           []))]
      (destroy n))))
{ : atom-node
  : container-node
  : custom-node
  : destroy
  : inspect-node
  :_tests { 
           : prepare-props
           : is-props-table}}
