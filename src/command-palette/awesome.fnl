(local awesome-global (require :awesome-global))
(local hotkeys-popup (require :awful.hotkeys_popup))
(local reload 
       {:label "Reload awesome"
        :exec awesome-global.awesome.restart})
(local quit
       {:label "Quit awesome"
        :exec #(awesome-global.awesome.quit)})
(local help
       {:label "Show keybindings"
        :exec hotkeys-popup.show_help})
  
[reload quit help]
