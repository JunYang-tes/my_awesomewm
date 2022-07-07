(local awful (require :awful))
(local { : key } (require :awful))
(local hotkeys-popup (require :awful.hotkeys_popup))
(local focus-win (require :windows.focus-win))
(local swap-win (require :windows.swap))                                   
(local gears (require :gears))                  
(local awesome-global (require :awesome-global))
(local {: terminal : modkey} (require :const)) 
(local tag (require :tag)) 
(local {: range} (require :utils.list))           
(local wibox  (require :wibox))
(local {: prompt } (require :ui.prompt))                           

(gears.table.join
 (_G.root.keys)
 (key [modkey] "h" hotkeys-popup.show_help 
      { :description "Show help"
        :group "awesome"}) 
 (key [modkey] "Left" awful.tag.viewprev 
      { :description "View previous" 
        :group "tag"}) 
 (key [modkey] "Right" awful.tag.viewnext 
      { :description "View next" 
        :group "tag"}) 
 (key [modkey] "Escape" awful.tag.history.restore 
      { :description "Go back" 
        :group "tag"}) 
 (key [modkey] "j" #(awful.client.focus.byidx 1)
      { :description "Focus next by index" 
        :group "client"}) 
 (key [modkey] "k" #(awful.client.focus.byidx -1)
      { :description "Focus previous by index" 
        :group "client"}) 
 (key [modkey] "f" #(focus-win.launch false) 
      { :description "Focus window"
        :group "client"}) 
 (key [modkey "Shift"] "f" (fn [] 
                            (local client awesome-global.client.focus)
                            (if client 
                              (do (set client.fullscreen (not client.fullscreen))))) 
      { :description "Focus window"
        :group "client"}) 
 (key [modkey] "w" #(print :TODO-Main-Menu) 
      { :description "Focus window"
        :group "client"}) 
 (key [modkey] "s" swap-win)
 (key [modkey "Shift"] "j" #(awful.client.swap.byidx 1) 
      { :description "swap with next client by index"
        :group "client"}) 
 (key [modkey "Shift"] "k" #(awful.client.swap.byidx -1) 
      { :description "swap with previous client by index"
        :group "client"}) 
 (key [modkey "Control"] "j" #(awful.client.swap.byidx 1) 
      { :description "swap with next client by index"
        :group "client"}) 
 (key [modkey "Control"] "k" #(awful.client.swap.byidx -1) 
      { :description "swap with previous client by index"
        :group "client"}) 
 (key [modkey "Control"] "u" awful.client.urgent.jmpto 
      { :description "jump to urgent client"
        :group "client"})
 (key [modkey "Control"] "Tab" 
      (fn []
        (awful.client.focus.history.previous)
        (if awesome-global.client.focus 
          (: awesome-global.client.focus :raise))) 
      { :description "Go back"
        :group "client"})
 (key [modkey ] "Return" #(awful.spawn terminal)
      { :description "open a terminal"
        :group "launcher"})
 (key [modkey "Control"] "r" #(awesome-global.awesome.restart)
      { :description "reload awesome"
        :group "awesome"})
 (key [modkey "Shift"] "q" #(awesome-global.awesome.quit)
      { :description "quit awesome"
        :group "awesome"})
 (key [modkey] "l" #(awful.tag.incmwfact 0.05)
      { :description "increase master width factor"
        :group "layout"})
 (key [modkey] "h" #(awful.tag.incmwfact -0.05)
      { :description "decrease master width factor"
        :group "layout"})
 (key [modkey "Shift"] "h" #(awful.tag.incnmaster 1 nil true)
      { :description "increase the number of master clients"
        :group "layout"})
 (key [modkey "Shift"] "l" #(awful.tag.incnmaster -1 nil true)
      { :description "decrease the number of master clients"
        :group "layout"})
 (key [modkey "Control"] "h" #(awful.tag.incncol 1 nil true)
      { :description "increase the number of columns"
        :group "layout"})
 (key [modkey "Control"] "l" #(awful.tag.incncol -1 nil true)
      { :description "decrease the number of columns"
        :group "layout"})
 (key [modkey] "space" #(awful.layout.inc 1)
      { :description "select next"
        :group "layout"})
 (key [modkey "Shift"] "space" #(awful.layout.inc -1)
      { :description "select previous"
        :group "layout"})
 (key [modkey] "r" #(awful.util.spawn "rofi -show drun")
      { :description "Run"
        :group "launcher"})
 (key [modkey] "w" #(awful.util.spawn "rofi -show window")
      { :description "Run"
        :group "launcher"})
 (key [modkey] "c" tag.create
      { :description "New tag"
        :group "tag"})
 (key [modkey] "n" tag.name-tag 
      { :description "Name a tag" 
        :group "tag"}) 
 (key [modkey] "t" tag.view-tag
      { :description "Name a tag" 
        :group "tag"})) 
