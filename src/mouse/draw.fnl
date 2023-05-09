(import-macros {: infix } :exp)
(local gears (require :gears))

(fn draw-grid [cr width height count]
  (cr:set_line_width 1)
  (cr:set_source (gears.color :#00ff00))
  (let [count (+ count 1)
        dx (/ width count)
        dy (/ height count)]
    (for [i 0 count]
      ; vertical line
      (cr:move_to (* dx i) 0)
      (cr:line_to (* dx i) height)
      ;horizontal line
      (cr:move_to 0 (* dy i))
      (cr:line_to width (* dy i)))
    (cr:stroke)))

(fn draw-cross [cr x y line-length]
  (let [line-length (or line-length 200)
        cx x
        cy y
        tick-distance 20
        tick-count (/ line-length tick-distance)
        tick-length 6]
    (cr:set_line_width 1)
    (cr:set_source (gears.color :#ff0000))
    ;horizontal
    (cr:move_to (infix cx - line-length / 2) cy)
    (cr:line_to (infix cx + line-length / 2) cy)
    ; vertical
    (cr:move_to cx (infix cy - line-length / 2))
    (cr:line_to cx (infix cy + line-length / 2))
    (for [i 1 (/ tick-count 2)]
      ;; horizontal tick
      (cr:move_to cx (+ cy (* i tick-distance)))
      (cr:line_to (+ cx tick-length) (+ cy (* i tick-distance)))
      (cr:move_to cx (- cy (* i tick-distance)))
      (cr:line_to (+ cx tick-length) (- cy (* i tick-distance)))
      ;; vertical tick
      (cr:move_to (+ cx (* i tick-distance)) cy)
      (cr:line_to (+ cx (* i tick-distance)) (+ cy tick-length))
      (cr:move_to (- cx (* i tick-distance)) cy)
      (cr:line_to (- cx (* i tick-distance)) (+ cy tick-length)))
    (cr:stroke)))

{ : draw-grid
  : draw-cross }
