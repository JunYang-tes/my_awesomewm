(fn catched [msg def ...]
  (let [f `(fn [])]
    (each [_ e (ipairs [...])]
      (table.insert f e))
    `(let [(ok# ret#) (xpcall ,f debug.traceback)]
        (if ok#
            ret#
            (do 
              (print ,msg ret#)
              ,def)))))
(fn catched-ignore [msg ...]
  (catched msg nil ...))

{ : catched
  : catched-ignore}
