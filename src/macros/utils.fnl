;; fennel-ls: macro-file
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

(fn time-it [title ...]
  (let [l `(do)]
    (each [_ e (ipairs [...])]
      (table.insert l e))
    `(do
       (local a# (os.clock))
       (local b# ,l)
       (local c# (os.clock))
       (print ,title  (* 1000 (- c# a#)))
       b#)))

{ : catch
  : time-it
  : catch-ignore}
