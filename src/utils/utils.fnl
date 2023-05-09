(local {: weak-table} (require :utils.table))
(local inspect (require :inspect))
(fn not-nil [val def]
  (if (not= val nil)
      val
      def))

(fn catch [f handle]
  (let [handle (or handle #(print :error-occured $1))]
    (fn [...]
      (let [(ok ret) (xpcall f debug.traceback ...)]
        (if ok
            ret
            (do
              (handle ret)
              nil))))))
(fn memoed [f]
  (let [cache (weak-table "kv")] 
    (setmetatable 
      {:clean (fn [a] (tset cache a nil))} 
      {:__call
        (fn [_ a]
          (let [r (. cache a)]
            (if (not= nil r)
              r
              (let [r (f a)]
                (if (and (not= nil a)
                         (not= nil r))
                  (tset cache a r))
                r))))})))
(fn is-number [s]
  (not= nil (tonumber s)))

(fn is-digital [s]
  (and (is-number)
       (= (length s) 1)))
(fn is-uppercase [s]
  (not= (string.match s "[A-Z]")
        nil))

{: not-nil
 : catch
 : is-number
 : is-digital
 : is-uppercase
 : memoed}
