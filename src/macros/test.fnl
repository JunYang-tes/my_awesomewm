(fn mk-test [name ...]
  (let [f `(fn [])]
    (each [_ e (ipairs [...])]
      (table.insert f e))
    `(tset test ,name ,f))) 
{
 : mk-test}
