(local awesome-global (require :awesome-global))
(local hotkeys-popup (require :awful.hotkeys_popup))
(local reload 
       {:label "reload-awesome"
        :exec awesome-global.awesome.restart})
(local quit
       {:label "quit-awesome"
        :exec awesome-global.awesome.quit})
(local help
       {:label "show-keybindings"
        :exec hotkeys-popup.show_help})
  
[reload quit help]
