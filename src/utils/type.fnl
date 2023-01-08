(local types (setmetatable {} {:__mode "k"}))
(fn make-type [name]
  {
        :mark-it (fn [obj] 
                   (tset types obj name))
        :is (fn [obj]
              (= name (. types obj)))})

(fn type-of [obj]
  (or (. types obj) :unknown))

{ : make-type
  : type-of}
