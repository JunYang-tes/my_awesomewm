(import-macros {: catched } :utils)
(local observable (require :lite-reactive.observable))
(local {: apply-property } (require :lite-reactive.observable))
(local list (require :utils.list))
(local {: weak-table 
        : assign
        : partition} (require :utils.table))
(local {: memoed} (require :utils.utils))
(local strings (require :utils.string))
(local inspect (require :inspect))
;;
;; type AtomNode = {
;;  :type :atom
;;  :build (props) => GtkWidget
;;  :props
;; }

;; type ContainerNode = {
;;   :type :Container
;;   :build (props)=>GtkWidget
;;   :update-children (children container ctx)=>void
;;   :relayout (container w ctx)=>void
;;   :props 
;;   :children Array<Node>| O<Array<Node>>
;;}
;; type CustomNode = {
;;   :type :custom
;;   :build (props,ctx)=>Node|Array<Node>
;;   :props 
;;   :children? Array<Node> | O<Array<Node>>
;;}
;; type Node = AtomNode | ContainerNode | CustomNode

(fn is-atom-node [node] 
  (= (. node :type) :atom))
(fn is-container-node [node]
  (= (. node :type) :container))
(fn is-custom-node [node]
  (= (. node :type) :custom))
(fn is-xprops [prop]
 (strings.starts-with prop :-)) 

(fn apply-xprop [node widget ctx name value]
  (apply-property value
                  (fn [value]
                    (ctx.add-xprops widget name value)
                    (let [parent (. node :parent)
                          container (parent)]
                      (parent.relayout container widget ctx)))))
(fn difference [nodes previous]
  (let [dict (collect [_ v (ipairs nodes)]
               v true)]
    (icollect [_ v (ipairs previous)]
      ;; v in previous but not in nodes
      (if (not (. dict v))
        v))))
(local CURRENT_CTX
  (let [env {}]
    { :set (fn [ctx]  (tset env :ctx ctx))
      :get (fn [] 
             (. env :ctx))}))

(fn make-runer [ctx]
  (var fns nil)
  (set fns
   { 
     :run-atom-node
     (fn [node]
        (let [[xprops props] (partition node.props #(is-xprops $1))
              w (node.build props)
              disposeable (icollect [name value (pairs xprops)]
                            (apply-xprop node w ctx (string.sub name 2) value))]
          (setmetatable node
            { :__call #w})
          ;; TODO dispose
          w))

              
     :run-container-node 
     (fn [node]
        (let [container (node.build node.props)
              children (observable.of node.children)]
          (setmetatable node
            { :__call #container})
          (fn observer [nodes previous]
            (each [_ n (ipairs (difference nodes (or previous [])))]
              (tset n :parent nil)
              (catched "Failed to clean" nil
                (ctx.clean n))
              (catched "Failed to clean run" nil
                (fns.run.clean n)))
            (each [_ n (ipairs nodes)]
              (tset n :parent node))
            (-> nodes
                (list.map #(fns.run $1))
                list.flatten
                (node.update-children container ctx)))
            ;;TODO dispose
          (children.add-observer observer)
          (observer (children))
          container))
     :run-custom-node
     (fn [node]
       (let [
             [xprops props] (partition node.props #(is-xprops $1))
             children (if (not= nil node.children)
                          (observable.of node.children)
                          nil)
             call-build (fn [props]
                          (CURRENT_CTX.set ctx)
                          (let [result (node.build props)]
                            (CURRENT_CTX.set nil)
                            result))
             w (-> (assign {: children } props)
                   call-build
                   fns.run)
             ;; pass down xprops
             disposeable (if (not (list.is-list w))
                             (icollect [name value (pairs xprops)]
                                (apply-xprop node w ctx name value))
                             [])]
          (print :returned w)
          w))
    :run
    (memoed
      (fn [node]
        (ctx.node-stack.push node)
        (let [result
              ((if
                (is-container-node node) fns.run-container-node 
                (is-custom-node node) fns.run-custom-node
                (is-atom-node node) fns.run-atom-node)
               node ctx)]
          (ctx.node-stack.pop)
          result)))})
  fns.run)
(fn build-ctx []
  (local node-stack 
         (let [stack {}]
            {
              :current #(. stack (length stack))
              :push (fn [node]
                      (table.insert stack node))
              :pop (fn []
                      (table.remove stack))}))
  (local xprops-cache (weak-table "k"))
  (fn add-xprops [key name value]
    (let [item (or 
                 (. xprops-cache key)
                 {})]
      (tset item name value)
      (tset xprops-cache key item)))
  (fn get-xprops [key def]
    (or (. xprops-cache key)
        def))
  (fn get-xprop [key name def]
    (or
      (.? xprops-cache key name)
      def))
  (fn clean [node]
    (let [disposeable (. node :disposeable)]
      (if disposeable
        (each [_ f (ipairs disposeable)]
          (catched "" nil (f))))))
  { : add-xprops
    : node-stack
    : get-xprop
    : get-xprops
    : clean})

(fn run [node]
  ((-> (build-ctx)
     make-runer) node))

(fn unmount [f]
  (catched 
    "unmount must be call inside a widget"
    nil
    (let [ctx  (CURRENT_CTX.get)
          node (ctx.node-stack.current)]
      (if (= nil node.disposeable)
          (tset node :disposeable []))
      (table.insert node.disposeable f))))
  

{: run  
 : unmount
 :_tests { : difference}}
