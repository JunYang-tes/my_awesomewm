(local wibox (require :wibox))
 
(fn is-props [tbl]
  (= (. tbl :--builder-role ) nil)) 

(fn make-layout-builder [method]
  (fn [props ...] 
    (print :props? (is-props props))
    (let [ (props children) (if (is-props props)
                                (values props [...]) 
                                (values {} [props ...]))] 
      (local tbl { :layout method})  
      (each [k v (pairs props)]
        (tset tbl k v))  
      (each [i v (ipairs children)] 
         (tset tbl i v)) 
      (tset tbl :--builder-role :layout)
      tbl)))
        

(local layout 
  {:fixed-horizontal (make-layout-builder wibox.layout.fixed.horizontal) 
   :fixed-vertical (make-layout-builder wibox.layout.fixed.vertical) 
   :align-horizontal (make-layout-builder wibox.layout.align.horizontal) 
   :align-vertical (make-layout-builder wibox.layout.align.vertical) 
   :flex-horizontal (make-layout-builder wibox.layout.flex.horizontal) 
   :flex-vertical (make-layout-builder wibox.layout.flex.vertical) 
   :manual (make-layout-builder wibox.layout.manual) 
   :stack (make-layout-builder wibox.layout.stack)}) 
                                                  

(fn make-container-builder [method method-key]
  (fn [props child]
    (let [ (props child) (match [props child] 
                           [nil nil] (error :must-have-child) 
                           [nil c] (values {} c) 
                           _ (values props child))] 
                   
      (print :props props :child child)
      (local tbl {}) 
      (tset tbl method-key method) 
      (tset tbl 1 child) 
      (each [k v (pairs props)] 
        (tset tbl k v)) 
      (tset tbl :--builder-role :container)
      tbl))) 
                           

(local container
  { :rotate (make-container-builder wibox.container.rotate :widget) 
    :scroll (make-container-builder wibox.container.rotate :layout) 
    :radial-progressbarl (make-container-builder wibox.container.radialprogressbar :widget) 
    :place (make-container-builder wibox.container.place :widget) 
    :mirror (make-container-builder wibox.container.mirror :widget) 
    :margin (make-container-builder wibox.container.margin :widget) 
    :constraint (make-container-builder wibox.container.constraint :widget) 
    :background (make-container-builder wibox.container.background :widget) 
    :arcchart (make-container-builder wibox.container.arcchart :widget)}) 
            
(fn make-widget-builder [widget]
  (fn [props] 
    (local tbl { : widget}) 
    (each [k v (pairs (or props nil))]                     
      (tset tbl k v)) 
    (print :widget tbl)
    (tset tbl :--builder-role :widget)
    tbl)) 

(local widget
  { :calendar-month (make-widget-builder wibox.widget.calendar.month) 
    :calendar-year (make-widget-builder wibox.widget.calendar.year) 
    :checkbox (make-widget-builder wibox.widget.checkbox) 
    :graph (make-widget-builder wibox.widget.graph) 
    :image-box (make-widget-builder wibox.widget.imagebox) 
    :pie-chart (make-widget-builder wibox.widget.piechart) 
    :progress-bar (make-widget-builder wibox.widget.progressbar) 
    :separator (make-widget-builder wibox.widget.separator) 
    :slider (make-widget-builder wibox.widget.slider) 
    :systray (make-widget-builder wibox.widget.systray) 
    :textbox (make-widget-builder wibox.widget.textbox) 
    :text-clock (make-widget-builder wibox.widget.textclock)}) 

{ : layout
  : container 
  : widget} 
                                                                        
