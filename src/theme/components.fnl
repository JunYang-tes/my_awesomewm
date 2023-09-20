(local titlebar (require :theme.win-clastic.titlebar))
(local taskbar (require :theme.win-clastic.taskbar))
(local gears (require :gears))
(local utils (require :utils.utils))
(local {: popup
        : imagebox} (require :ui.node))
(local {: run } (require :lite-reactive.app))
(local {: set-wallpaper} (require :theme.win-clastic.wallpaper))
(local win-switcher (require :theme.win-clastic.win-switcher))


{: titlebar
 : set-wallpaper
 : win-switcher
 : taskbar}
