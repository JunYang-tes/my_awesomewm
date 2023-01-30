(fn catch [msg def ...]
  (let [f `(fn [])]
    (each [_ e (ipairs [...])]
      (table.insert f e))
    `(let [(ok# ret#) (xpcall ,f debug.traceback)]
        (if ok#
            ret#
            (do 
              (print ,msg ret#)
              ,def)))))
(fn catch-ignore [msg ...]
  (catch msg nil ...))

{ : catch
  : catch-ignore}
