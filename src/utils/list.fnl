(fn some [list predict?]
  (var found false)
  (each [_ item (ipairs list) :until found]
    (if (predict? item)
      (set found true)))
  found)

(fn map [list f]
  (icollect [i v (ipairs list)]
    (f v i)))

(fn find [list predict?]
  (var found nil)
  (each [_ item (ipairs list) :until found]
    (if (predict? item)
        (set found item)))
  found)

(fn range [from to step]
  (local list [])
  (var start from)
  (while (< start to)
    (table.insert list start)
    (set start (+ start (or step 1))))
  list)

(fn zip [ a b]
  (let [ [ x y] (if (< (length a) (length b))
                    [a b]
                    [b a])]
    (icollect [i v (ipairs x)]
      [(. a i) (. b  i)])))

(fn concat [a b]
  (local r [(table.unpack a)])
  (each [_ v (ipairs b)]
    (table.insert r v))
  r)

(fn filter [list should-remain?]
  (icollect [_ v (ipairs list)]
    (if (should-remain? v)
        v)))

(fn find-index [list entry]
  (-> list
    (map (fn [v i] [i v]))
    (filter (fn [[i v]] (= v entry)))
    (. 1)))

(fn remove-value! [list value]
  (var ind   0)
  (each [i v (ipairs list)]
    (if (= v value)
        (set ind i)))
  (if (> ind 0)
      (table.remove list ind))
  list)

(fn push [list value]
  (let [r (map list (fn [a] a))]
    (table.insert r value)
    r))

(fn reduce [list accumulator init]
  (var ret init)
  (each [i v (ipairs list)]
    (set ret (accumulator v ret)))
  ret)

(fn every [list predict?]
  (reduce
    list
    (fn [item acc]
      (and acc (predict? item)))
    true))

(fn max-by [list accessor]
  (reduce
    list
    (fn [item acc]
      (local a (accessor item))
      (local b (accessor acc))
      (if (> a b)
          item
          acc))
    (. list 1)))

(fn min-by [list accessor]
  (reduce
    list
    (fn [item acc]
      (local a (accessor item))
      (local b (accessor acc))
      (if (> a b)
          acc
          item))
    (. list 1)))
(fn no-key? [obj]
  (var no-key true)
  (each [k v (pairs obj)]
    (set no-key false))
  no-key)

(fn is-list [obj]
  (let [t (type obj)]
    (and
      (= t :table)
      (or
        (. obj :--is-list)
        (> (length obj) 0)
        (no-key? obj)))))

(fn flatten [list]
  (fn flatten-impl [ret list]
    (each [_ v (ipairs list)]
      (if (is-list v)
          (flatten-impl ret v)
          (table.insert ret v))))
  (let [ret []]
    (flatten-impl ret list)
    ret))

(fn partition [list predicate?]
  (reduce
    list
    (fn [item acc]
      (if (predicate? item)
        (table.insert (. acc 1) item)
        (table.insert (. acc 2) item))
      acc)
    [[] []]))

(fn split-by [list predicate?]
  (let [{: collecting : splited}
        (reduce
          list
          (fn [item acc]
            (if (predicate? item)
              (do
                (if (> (length acc.collecting) 0)
                    (do
                      (table.insert acc.splited acc.collecting)
                      (tset acc :collecting [])))
                (table.insert acc.collecting item))
              (table.insert acc.collecting item))
            acc)
          {:collecting []
           :splited []})]
    (if (> (length collecting) 0)
        (table.insert splited collecting))
    splited))

{
  : filter
  : map
  : some
  : every
  : range
  : concat
  : find-index
  : find
  : is-list
  : flatten
  : remove-value!
  : reduce
  : max-by
  : min-by
  : partition
  : zip
  : push
  : split-by}
