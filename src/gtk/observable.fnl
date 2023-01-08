(local { : make-type } (require :utils.type))
(local obserable (setmetatable {} {:__mode "k"}))
(local observable_type (make-type :observable))

(fn is-observable [obj]
  (observable_type.is obj))

(fn value [initial] 
  (var value initial)
  (local observers [])
  (local weak-observers (setmetatable {} {:__mode "v"}))
  (fn set-value [new]
     (if (not= new value)
      (do
        (local curr value)
        (set value new)
        (each [_ ob (ipairs observers)]
          (print (pcall ob new curr)))
        (each [_ ob (ipairs weak-observers)]
          (print (pcall ob new curr))))))
  (local result (setmetatable 
                    {
                      :set set-value
                      :get (fn [] value)
                      :add-observer (fn [observer]
                                      (table.insert observers observer))
                      :add-weak-observer (fn [observer]
                                           (table.insert weak-observers observer))}
                    {:__call (fn [_ new] 
                               (if (not= nil new)
                                   (set-value new)
                                   value))
                     :__tostring #(.. "Observable(" (tostring value) ")")}))
  (observable_type.mark-it result)
  result)


;; (Observable<T>, T=>U) => Observable<U>
;; (T,T=>U)=>U
(fn map [obserable f]
  (if (is-observable obserable)
    (let [val (value (f (obserable.get)))]
      (fn observe [new] (val.set (f new)))
      (obserable.add-weak-observer observe)
      (tset val :observe observe)
      val)
    (f obserable)))
(fn mapn [...]
  (let [list [...]]
    (let [f (. list (length list))]
      (table.remove list)
      (let [val (value (f (table.unpack (icollect [i v (ipairs list)] (v)))))]
        (each [_ v (ipairs list)]
          (v.add_observer
            (fn [] (val.set (f (table.unpack (icollect [i v (ipairs list)] (v))))))))
        val))))

(fn pick [observable key]
  (map observable #(. $1 key)))

(fn of [val]
  (if (is-observable val)
      val
      (value val)))

{ : value 
  : of
  : map
  : pick
  : is-observable
  : mapn}
