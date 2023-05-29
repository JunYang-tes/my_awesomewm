(local awful (require :awful))
(local stringx (require :utils.string))
(local { : some
         : map
         : reduce
         : flatten } (require :utils.list))
(local inspect (require :inspect))
(local screens {})

(fn key-screen [screen]
  (screen.outputs))

(local inferaces
  [
   #(stringx.starts-with $1 "HDMI")
   #(stringx.starts-with $1 "DP")
   #(stringx.starts-with $1 "DisplayPort")
   #(stringx.starts-with $1 "eDP")
   #(stringx.starts-with $1 "VGA")])

(fn parse-interface [screen]
  (var interface screen.index)
  (each [k v (pairs (or screen.outputs {}))]
    (if (some inferaces #($1 k))
        (set interface k)))
  (tostring interface))

(awful.screen.connect_for_each_screen
  (fn [screen]
    (tset screens (parse-interface screen) screen)))

(awful.screen.disconnect_for_each_screen
  (fn [screen]
    (tset screens (parse-interface screen) nil)))

(fn is-screen [in]
  (and (= (type in ) :table)
       (= (type (. :screen in)) :function)))

(fn get-prefered-screen [query]
  (if query
    (match (stringx.split query ":")
      ["" :focused] (awful.screen.focused)
      ["" :primary] awful.screen.primary
      ["interface" interface] (or (. screens interface)
                                  (awful.screen.focused))
      _ (awful.screen.focused))
    (awful.screen.focused)))

(fn get-name [screen]
  (parse-interface screen))

(fn get-screens []
  screens)

(fn get-screen-list []
  (icollect [_ v (pairs screens)]
    v))

(fn calc-pos [s x y]
  (local workarea s.workarea)
  { :x (+ x workarea.x)
    :y (+ y workarea.y)})
(fn center [screen w h]
  (local {: width : height} screen.geometry)
  (local pos (calc-pos screen (/ (- width w) 2)
                              (/ (- height h) 2)))
  pos)

(fn wrap-mouse-fns [fns get-screen]
  (let [
        new {}]
    (each [k v (pairs fns)]
      (tset new k (fn [x y]
                    (let [screen (get-screen)
                          geometry screen.geometry]
                      (v (+ x geometry.x)
                         (+ y geometry.y))))))
    new))

(fn wrap-mouse-fns-on-focused [fns]
  (wrap-mouse-fns fns awful.screen.focused))

(fn geometry []
  (fn get-result [v]
    {:x v.x
         :y v.y
         :width (- v.mx v.x)
         :height (- v.my v.y)})
  (-> (get-screen-list)
      (map #(let [{: height
                   : width
                   : x
                   : y} $1.geometry]
              [{: x : y}
               {:x (+ x width)
                :y (+ y height)}]))
      (flatten)
      (reduce (fn [v acc]
                { :x (if (< v.x acc.x)
                       acc.x
                       v.x)
                  :y (if (< v.y acc.y)
                       acc.y
                       v.y)
                  :mx (if (> v.x acc.mx)
                        v.x
                        acc.mx)
                  :my (if (> v.y acc.my)
                        v.y
                        acc.my)})
                  
              {:x 0
               :y 0
               :mx 0
               :my 0})
      get-result))

(fn clients []
  (-> (get-screen-list)
      (map #(. $1 :selected_tag))
      (map #($1:clients))
      (flatten)))


{ : get-prefered-screen
  : parse-interface
  : get-name
  : is-screen
  : calc-pos
  : center
  : wrap-mouse-fns
  : wrap-mouse-fns-on-focused
  : get-screen-list
  : get-screens
  : clients
  : geometry}
