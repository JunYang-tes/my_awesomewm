(local awful (require :awful))
(local wibox (require :wibox)) 
(local builder (require :ui.builder)) 

(local popup (awful.popup {
                           :widget
                             (wibox.widget 
                              (builder.container.background 
                               {:bg :#ff0000} 
                               (builder.layout.fixed-horizontal  
                                  (builder.container.margin
                                    {:right 100} 
                                    (builder.widget.textbox 
                                        {:markup "Hello "})) 
                                  (builder.widget.text-clock)
                                  (builder.widget.textbox 
                                    {:markup "World "})))) 
                           :ontop true 
                           :visble true})) 
                           

{ :clear (fn []
           (tset package.loaded :ui.demo nil))}
         
