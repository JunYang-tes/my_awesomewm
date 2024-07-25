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

(fn get-codebase-dir []
  (let [config-path (os.getenv "AWESOME_CONFIG")]
    (if (not config-path)
        (error "AWESOME_CONFIG not set"))
    (.. config-path
        "/lua")))

(fn id []
  (string.gsub
    :xxxxxxxx_xxxx_4xxx_yxxx_xxxxxxxxxxxx
    "[xy]"
    (fn [c]
      (let [v (if (= c :x)
                (math.random 0 0xf)
                (math.random 9 0xb))]
        (string.format :%x v)))))

{: not-nil
 : catch
 : is-number
 : is-digital
 : get-codebase-dir
 : id
 : is-uppercase
 : memoed}
