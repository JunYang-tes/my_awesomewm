(local shape (require :gears.shape))
(fn rrect [radius]
  (fn [cr width height]
    (shape.rounded_rect cr width height radius))) 
                       

{ : rrect}
