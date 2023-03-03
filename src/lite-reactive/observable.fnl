(local { : make-type } (require :utils.type))
(local { : weak-value-table
         : weak-key-table} (require :utils.table))
(local obserable (setmetatable {} {:__mode "k"}))
(local observable_type (make-type :observable))
(local list (require :utils.list))

(fn is-observable [a]
  (and
    (= :table (type a))
    (. a :--observable)))
(fn apply-property [value setter]
  (if (is-observable value)
    (do
      (setter (value))
      (value.add-observer #(setter $1 $2)))
    (do
      (setter value)
      #$)))

(fn value [initial] 
  (var value initial)
  (local observers [])
  (local weak-observers (weak-value-table))
  (fn set-value [new]
     (if (not= new value)
      (do
        (local curr value)
        (set value new)
        (each [_ ob (ipairs observers)]
          (let [(ok res) (pcall ob new curr)]
            (if (not ok)
              (print res))))
        (each [_ ob (ipairs weak-observers)]
          (let [(ok res) (pcall ob new curr)]
            (if (not ok)
              (print res)))))))
  (local result (setmetatable 
                    {
                      :set set-value
                      :get (fn [] value)
                      :add-observer (fn [observer]
                                      (table.insert observers observer)
                                      (fn remove [] 
                                        (list.remove-value! observers observer)))
                      :add-weak-observer (fn [observer]
                                           (table.insert weak-observers observer)
                                           (fn remove []
                                             (list.remove-value! weak-observers observer)))
                      :weak-observer-count #(length weak-observers)
                      :--observable true}
                    {:__call (fn [_ new] 
                               (if (not= nil new)
                                   (set-value new)
                                   value))
                     :__tostring #(.. "Observable(" (tostring value) ")")}))
  (observable_type.mark-it result)
  result)

(fn of [val]
  (if (is-observable val)
      val
      (value val)))

(fn add-observer [observable obj f]
  (tset obj :observe f)
  (observable.add-weak-observer f))

;; (Observable<T>, T=>U) => Observable<U>
;; (T,T=>U)=>U
(fn map [obserable f]
  (if (is-observable obserable)
    (let [val (value (f (obserable.get)))]
      (fn observer [new]
        (val (f new)))
      (add-observer obserable val observer)
      val)
    (f obserable)))
;; ([O<T1> ... O<Tn>], ([T1...Tn])=>U) => O<U>
(fn mapn [observables f]
  (let [r (value (f (list.map observables #($1))))]
    (fn observer [] (r.set (f (list.map observables #($1)))))
    (each [_ v (ipairs observables)]
      (v.add-weak-observer observer))
    (tset r :observer observer)
    r))
;; (O<Array<T>>, T=>U) => O<Array<U>>
(fn map-list [o f]
  (map o #(list.map $1 #(f $1 $2)))) 

;; Observable<Observable<T>> => Observable<T>
(fn flat [obj]
  (let [inner (of (obj))
        final (inner)
        r (value final)]
    (fn listen-inner [value]
      (r value))
    (var remove (inner.add-weak-observer listen-inner))
    (fn listen-obj [newInner]
      (let [
            newInner (of newInner)
            final (newInner)]
        (remove)
        (set remove (newInner.add-weak-observer listen-inner))
        (r final)))
    (obj.add-weak-observer listen-obj)
    (tset r :observer1 listen-inner)
    (tset r :observer2 listen-obj)
    r))

;; Observable<T>,(T=>Observable<U>)=>Observable<U>
(fn flat-map [obj f]                      
  (flat (map obj f)))

(fn get-impl [obj]
  (if (is-observable obj)
      (get-impl (obj))
      obj))
;; Observable<Observable<...Observable<T>>> => T 
(fn get [obj]
  (get-impl obj))

(fn observe-deep [obj f]
  (local remove [])
  (var add-observer nil)
  (fn weak-observer []
    (each [_ r (ipairs remove)]
        (r))
    (add-observer obj)
    (f))
  (set 
    add-observer
    (fn [obj]
      (if (is-observable obj)
          (do
            (table.insert remove
              (obj.add-weak-observer weak-observer))
            (add-observer (obj))))))

  (add-observer obj)
  (tset obj :observer weak-observer)
  obj)

;; Observable<Observable<...>> => Observable<T> where T is not Observable
(fn flat-deep [obj]
  (let [r (value (get obj))]
    (observe-deep obj (fn [] 
                        (r (get obj))))
    r))

(fn pick [observable key]
  (map observable #(. $1 key)))
(fn flat-collect [obj]
  (let [r []]
    (fn collect-imp [obj]
      (if (is-observable obj)
          (collect-imp (obj))
          (list.is-list obj)
          (each [_ v (ipairs obj)]
            (collect-imp v))
          (table.insert r obj)))
    (collect-imp obj)
    r))


{ : value 
  : flat
  : flat-deep
  : of
  : observe-deep
  : map
  : map-list
  : flat-map
  : get
  : flat-collect
  : pick
  : is-observable
  : apply-property
  : mapn}
