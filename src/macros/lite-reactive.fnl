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
(fn effect [obs ...]
  (let [run-effect `(fn [])]
    (each [_ e (ipairs [...])]
      (table.insert run-effect e))
    `(let [dispose# (icollect [_# k# (ipairs ,obs)]
                       (k#.add-observer ,run-effect))]
        (unmount
          (each [_# f# (ipairs dispose#)]
             (f#))))))

     
  

{ : defn
  : unmount
  : effect}
