(fn defc [name ...]
  (let [p (sym :props)
        ctx (sym :ctx)]
    (let [f `(fn [,p ,ctx])]
      (each [_ e (ipairs [...])]
        (table.insert f e))
      `(local ,name (let [{:custom-node custom-node# } (require :lite-reactive.node)]
                     (custom-node# ,f))))))
(fn unmount [...]
  (let [f `(fn [])]
    (each [_ e (ipairs [...])]
      (table.insert f e))
    `(let [{:unmount unmt#} (require :lite-reactive.app)]
       (unmt# ,f))))

{ : defc
  : unmount}
