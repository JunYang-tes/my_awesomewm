(import-macros {: infix } :exp)
(local {: assign } (require :utils.table))
(local lgi (require :lgi))
(local cairo lgi.cairo)

(fn copy-mat [mat]
  (let [new (cairo.Matrix.create_identity)]
    (new:multiply new mat)
    new))

(fn make-selector [transform]
  (fn [mat w h]
    (let [new (copy-mat mat)]
      (transform new w h mat)
      new)))
(local panel-selector
  {:q (make-selector (fn [mat w h]
                       (mat:scale (/ 1 3)
                                  (/ 1 3))))
   :w (make-selector (fn [mat w h original]
                       (mat:translate (/ w 3) 0)
                       (mat:scale (/ 1 3)
                                  (/ 1 3))))
   :e (make-selector (fn [mat w h original]
                       (mat:translate (infix 2 * w / 3) 0)
                       (mat:scale (/ 1 3)
                                  (/ 1 3))))
   :a (make-selector (fn [mat w h original]
                       (mat:translate 0 (/ h 3))
                       (mat:scale (/ 1 3)
                                  (/ 1 3))
                       ))
   :s (make-selector (fn [mat w h original]
                       (mat:translate (/ w 3) (/ h 3))
                       (mat:scale (/ 1 3)
                                  (/ 1 3))))
   :d (make-selector (fn [mat w h original]
                       (mat:translate (infix w / 3 * 2)
                                      (/ h 3))
                       (mat:scale (/ 1 3)
                                  (/ 1 3))))
   :z (make-selector (fn [mat w h original]
                       (let [w (/ w 3)
                             h (/ h 3)]
                         (mat:translate 0 (* 2 h))
                         (mat:scale (/ 1 3)
                                    (/ 1 3)))))
   :x (make-selector (fn [mat w h original]
                       (let [w (/ w 3)
                             h (/ h 3)]
                         (mat:translate w (* 2 h))
                         (mat:scale (/ 1 3)
                                    (/ 1 3)))))
   :c (make-selector (fn [mat w h]
                       (let [w (/ w 3)
                             h (/ h 3)]
                         (mat:translate (* 2 w)
                                        (* 2 h))
                         (mat:scale (/ 1 3)
                                    (/ 1 3)))))})

(local position-motion
  {:j (fn [size pos]
        (assign pos 
                {:y (+ pos.y size)}))
   :k (fn [size pos]
        (assign pos
                {:y (- pos.y size)}))
   :h (fn [size pos]
        (assign pos
                {:x (- pos.x size)}))
   :l (fn [size pos]
        (assign pos
                {:x (+ pos.x size)}))
   })

{ : copy-mat
  : make-selector
  : panel-selector
  : position-motion}
