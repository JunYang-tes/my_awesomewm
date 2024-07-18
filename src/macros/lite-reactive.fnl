;; fennel-ls: macro-file
(fn defn [name ...]
  (let [p (sym :props)
        ctx (sym :ctx)]
    (let [f `(fn [,p ,ctx])]
      (each [_ e (ipairs [...])]
        (table.insert f e))
      `(local ,name (let [{:custom-node custom-node# } (require :lite-reactive.node)]
                     (custom-node# ,f ,(. name 1)))))))
(fn unmount [...]
  (let [f `(fn [])]
    (each [_ e (ipairs [...])]
      (table.insert f e))
    `(let [{:unmount unmt#} (require :lite-reactive.app)]
       (unmt# ,f))))
(fn onchange [obs ...]
  (let [old (sym :old)
        new (sym :new)
        executor `(fn [,new ,old])]
    (each [_ e (ipairs [...])]
      (table.insert executor e))
    `(let [r# (require :lite-reactive.observable)
           val# (r#.mapn ,obs #$1)]
       (val#.add-observer
         ,executor)
       (unmount 
         (val#.destroy)))))

(fn effect [obs ...]
  (let [run-effect `(fn [])]
    (each [_ e (ipairs [...])]
      (table.insert run-effect e))
    `(let [noop# (fn [])
           effect-clearup# {:clear noop#}
           observer# (fn [...]
                         (effect-clearup#.clear)
                         (tset effect-clearup# :clear noop#)
                         (let [ret# (,run-effect)]
                           (if (= (type ret#) :function)
                             (tset effect-clearup# :clear ret#))))
           dispose# (icollect [_# k# (ipairs ,obs)]
                       (k#.add-observer observer#))]
        (observer#)
        (unmount
          (each [_# f# (ipairs dispose#)]
             (f#))))))


{ : defn
  : unmount
  : onchange
  : effect}
