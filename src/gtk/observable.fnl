(local { : make-type } (require :utils.type))
(local obserable (setmetatable {} {:__mode "k"}))
(local observable_type (make-type :observable))

(fn is-observable [obj]
  (observable_type.is obj))

(fn value [initial] 
  (var value initial)
  (local observers [])
  (local weak-observers (setmetatable {} {:__mode "v"}))
  (local result (setmetatable 
                    {
                      :set (fn [new] 
                             (if (not= new value)
                              (do
                                (local curr value)
                                (set value new)
                                (each [_ ob (ipairs observers)]
                                  (print (pcall ob new curr)))
                                (each [_ ob (ipairs weak-observers)]
                                  (print (pcall ob new curr))))))
           
                      :get (fn [] value)
                      :add-observer (fn [observer]
                                      (table.insert observers observer))
                      :add-weak-observer (fn [observer]
                                           (table.insert weak-observers observer))}
                    {:__call (fn [] value)}))
  (observable_type.mark-it result)
  result)


(fn map [obserable f]
  (let [val (value (f (obserable.get)))]
    (fn observe [new] (val.set (f new)))
    (obserable.add-weak-observer observe)
    (tset val :observe observe)
    val))
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
  

{ : value 
  : map
  : pick
  : is-observable
  : mapn}
