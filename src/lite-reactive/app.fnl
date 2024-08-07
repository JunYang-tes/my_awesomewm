(import-macros {: catch } :utils)
(import-macros {: defn } :lite-reactive)
(local observable (require :lite-reactive.observable))
(local {: apply-property } (require :lite-reactive.observable))
(local list (require :utils.list))
(local utils (require :utils.utils))
(local {: weak-table 
        : assign
        : partition} (require :utils.table))
(local utils (require :utils.utils))
(local strings (require :utils.string))
(local inspect (require :inspect))
(local {: destroy : inspect-node } (require :lite-reactive.node))
;;
;; type AtomNode = {
;;  :type :atom
;;  :build (props) => GtkWidget
;;  :props
;;  :name
;;  :parent Node
;; }

;; type ContainerNode = {
;;   :type :Container
;;   :build (props)=>GtkWidget
;;   :update-children (children container ctx)=>void
;;   :relayout (container w ctx)=>void
;;   :props 
;;   :children Array<Node>| O<Array<Node>>
;;  :parent Node
;;}
;; type CustomNode = {
;;   :type :custom
;;   :build (props,ctx)=>nil| Node|Array<Node>
;;   :props 
;;   :children? Array<Node> | O<Array<Node>>
;;   :build-result Array<Node>
;;}
;; type Node = AtomNode | ContainerNode | CustomNode

(fn is-atom-node [node] 
  (and 
    (= (type node) :table)
    (= (. node :type) :atom)))
(fn is-container-node [node]
  (and 
    (= (type node) :table)
    (= (. node :type) :container)))
(fn is-custom-node [node]
  (and 
    (= (type node) :table)
    (= (. node :type) :custom)))
(fn is-xprops [prop]
 (strings.starts-with prop :-)) 

(fn apply-xprop [node widget ctx name value]
  (apply-property value
                  (fn [value]
                    (ctx.add-xprops widget name value)
                    (catch "" ""
                      (let [parent (. node :parent)
                            container (parent)]
                        (parent.relayout container widget ctx))))))
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
(fn set-diposeable! [node disposeable]
  (if (= nil node.disposeable)
    (tset node :disposeable []))
  (each [_ f (ipairs disposeable)]
    (table.insert node.disposeable f)))
  
(fn clean [node]
  (let [disposeable (. node :disposeable)]
    (if disposeable
      (each [_ f (ipairs disposeable)]
        (catch "" nil (f))))))
(fn make-runer [ctx]
  (local memoed utils.memoed)
  (var fns nil)
  (set fns
   { 
     :run-atom-node
     (fn [node]
        (let [[xprops props] (partition node.props #(is-xprops $1))
              call-build (fn []
                          (CURRENT_CTX.set ctx)
                          (let [r (node.build props)]
                            (CURRENT_CTX.set nil)
                            r))
              w (call-build)
              disposeable (icollect [name value (pairs xprops)]
                            (apply-xprop node w ctx (string.sub name 2) value))]
          (setmetatable node
            { :__call #w})
          (set-diposeable! node disposeable)
          w))

     :run-container-node 
     (fn [node]
        (let [
              [xprops props] (partition node.props #(is-xprops $1))
              container (node.build props)
              children (observable.of node.children)
              disposeable (icollect [name value (pairs xprops)]
                            (apply-xprop node container ctx (string.sub name 2) value))]
          (setmetatable node
            { :__call #container})
          (fn observer [nodes previous]
            (let [nodes (list.filter nodes #$)
                  previous (list.filter (or previous []) #$)]
              (each [_ n (ipairs (difference nodes (or previous [])))]
                (tset n :parent nil)
                (catch "Failed to clean" nil
                  (ctx.clean n)))
                ;; (catch "Failed to clean run" nil
                ;;   (fns.run.clean n)))
              (each [_ n (ipairs nodes)]
                (tset n :parent node))
              (-> nodes
                  (list.map #(fns.run $1))
                  list.flatten
                  (node.update-children container ctx))))
          (set-diposeable! node disposeable)
          (set-diposeable! node [
                                  (children.add-observer observer)])
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
                          (let [
                                result (node.build props)]
                            (CURRENT_CTX.set nil)
                            (if (= result nil)
                                []
                                result)))
                            ;; (if (list.is-list result)
                            ;;   (each [_ child (ipairs result)]
                            ;;     (tset child :parent node))
                            ;;   (tset result :parent node))
             returned-node (-> (call-build (assign {: children } props)))
             w (if (list.is-list returned-node)
                   (list.map returned-node fns.run)
                   (fns.run returned-node))
             ;; pass down xprops
             disposeable (if (not (list.is-list w))
                             (icollect [name value (pairs xprops)]
                                (apply-xprop node w ctx name value))
                             [])]
          (setmetatable node
            {:__call #w})
          ;; (table.insert disposeable 
          ;;               (fn []
          ;;                 (if (list.is-list returned-node)
          ;;                   (each [_ n (ipairs returned-node)]
          ;;                     (destroy n))
          ;;                   (destroy returned-node))))
          (tset node :build-result 
                (if (list.is-list returned-node)
                    returned-node
                    [returned-node]))
          (set-diposeable! node disposeable)
          w))
    :run
    (memoed
     (fn [node]
       (ctx.node-stack.push node)
       (let [result
             ((if
               (is-container-node node) fns.run-container-node 
               (is-custom-node node) fns.run-custom-node
               (is-atom-node node) fns.run-atom-node
               (fn []
                 (error (.. "unknow node: " (tostring node)))))
              node ctx)]
         (if node.on-built
           (node.on-built result))
         (ctx.node-stack.pop)
         (if node.props.id
           (ctx.set-widget node.props.id result))
         result)))})
  fns.run)
(fn build-ctx [root]
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
      (?. xprops-cache key name)
      def))
  (fn get-root [] root)
  (local widgets-cache (weak-table "v"))
  (fn get-widget [id]
    (. widgets-cache id))
  (fn set-widget [id widget]
    (tset widgets-cache id widget))
  { : add-xprops
    : node-stack
    : get-xprop
    : get-xprops
    : get-root
    : get-widget
    : set-widget
    : clean})

(lambda run [node]
  (let [ctx (build-ctx node)
        run (make-runer ctx)]
    (tset ctx :run run)
    (run node)))

(lambda unmount [f]
  (catch
    "unmount must be called inside a node"
    nil
    (let [ctx  (CURRENT_CTX.get)
          node (ctx.node-stack.current)]
      (if (= nil node.disposeable)
          (tset node :disposeable []))
      (table.insert node.disposeable f))))
(fn use-widget []
  (let [ctx (CURRENT_CTX.get)]
    (catch
      "use-widget must be called inside a node" nil
      (fn [id]
        (ctx.get-widget id)))))
  
(fn use-root []
  (catch
    "use-root must be called inside a node"
    nil
    (let [ctx (CURRENT_CTX.get)
          root (ctx.get-root)]
      root)))
(fn use-built []
  (catch
    "use-built must be called inside a node"
    nil
    (let [ctx (CURRENT_CTX.get)
          node (ctx.node-stack.current)
          ret (observable.value false)]
      (tset node :on-built #(ret $1))
      ret)))

(fn use-onbuilt [cb]
  (local built (use-built))
  (var remove nil)
  (fn observer [widget]
    (when widget
      (cb widget)
      (remove)))
  (set remove (built.add-observer observer)))

(fn use-destroy []
  (let [root (use-root)]
    (fn []
      (destroy root))))
(fn use-run []
  (let [ctx (CURRENT_CTX.get)]
    (lambda [node nomemo]
      (let [r (ctx.run node)]
        (when nomemo
          (ctx.run.clean node))
        r))))
(lambda foreach [items render]
  (let [memoed-render (utils.memoed (fn [data] (render data)))
        items (observable.of items)]
    (observable.map-list items memoed-render)))
    ;; (observable.map 
    ;;   items
    ;;   (fn [items])
    ;;   #(list.map $1 memoed-render))))

{: run
 : unmount
 : foreach
 : use-destroy
 : use-built
 : use-widget
 : use-run
 : use-onbuilt
 :_tests { : difference}}
