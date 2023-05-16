(local {: last-index} (require :utils.string))
(fn basename [path]
  (let [ind (or (last-index path "/")
                0)]
    (string.sub path (+ ind 1))))

{: basename}
