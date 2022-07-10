;; https://github.com/rxyhn/dotfiles/blob/main/config/awesome/theme/theme.lua
(local gears (require :gears))
(local gfs (require :gears.filesystem)) 
(local themes_path (gfs.get_themes_dir)) 
(local theme (dofile (.. themes_path "default/theme.lua"))) 
(local theme_assets (require :beautiful.theme_assets)) 
(local xresources (require :beautiful.xresources))                                                    
(local dpi xresources.apply_dpi) 
(local ui (require :utils.ui)) 
           

(macro assign [tgt src]
  (list (sym :do)
    (icollect [i k (ipairs src)] 
        (if (not= (% i 2) 0) 
          (do 
            (local v (. src (+ i 1))) 
            (list (sym :tset) tgt k v)))) 
    tgt)) 


(assign
  theme 
  [ 
    :wallpapers_path (.. (os.getenv "HOME")
                         "/.config/awesome/src/theme/wallpapers") 
    ;; Specail
    :xforeground  "#D9D7D6"
    :darker_xbackground  "#000a0e"
    :xbackground  "#061115"
    :lighter_xbackground  "#0d181c"
    :one_bg  "#131e22"
    :one_bg2  "#1c272b"
    :one_bg3  "#242f33"
    :grey  "#313c40"
    :grey_fg  "#3b464a"
    :grey_fg2  "#455054"
    :light_grey  "#4f5a5e"
    :transparent  "#00000000"

    ;; Black
    :xcolor0  "#1C252C"
    :xcolor8  "#484E5B"

    ;; Red
    :xcolor1  "#DF5B61"
    :xcolor9  "#F16269"

    ;; Green
    :xcolor2  "#78B892"
    :xcolor10  "#8CD7AA"

    ;; Yellow
    :xcolor3  "#DE8F78"
    :xcolor11  "#E9967E"

    ;; Blue
    :xcolor4  "#6791C9"
    :xcolor12  "#79AAEB"

    ;; Magenta
    :xcolor5  "#BC83E3"
    :xcolor13  "#C488EC"

    ;; Cyan
    :xcolor6  "#67AFC1"
    :xcolor14  "#7ACFE4"

    ;; White
    :xcolor7  "#D9D7D6"
    :xcolor15  "#E5E5E5" 

    ;; Ui Fonts
    :font_name  "Roboto "
    :font  (.. "Roboto "  "Medium 10")

    ;; Icon Fonts
    :icon_font  "Material Icons "

    ;; Background Colors
    :bg_normal  theme.xbackground
    :bg_focus  theme.xbackground
    :bg_urgent  theme.xbackground
    :bg_minimize  theme.xbackground

    ;; Foreground Colors
    :fg_normal  theme.xforeground
    :fg_focus  theme.accent
    :fg_urgent  theme.xcolor1
    :fg_minimize  theme.xcolor0

    :accent  theme.xcolor4

    ;; UI events
    :leave_event  transparent
    :enter_event  "#ffffff10"
    :press_event  "#ffffff15"
    :release_event  "#ffffff10"

    ;; Widgets
    :widget_bg  "#162026"
    ;; Titlebars
    :titlebar_enabled  true
    :titlebar_bg  theme.xbackground
    :titlebar_fg  theme.xforeground

    ;; Wibar
    :wibar_bg  "#0B161A"
    :wibar_height  (dpi 40)

    ;; Music
    :music_bg  theme.xbackground
    :music_bg_accent  theme.darker_xbackground
    :music_accent  theme.lighter_xbackground

    :icon_theme  "WhiteSur-dark"

    ;; Borders
    :border_width  0
    :oof_border_width  0
    :border_color_marked  theme.titlebar_bg
    :border_color_active  theme.titlebar_bg
    :border_color_normal  theme.titlebar_bg
    :border_color_new  theme.titlebar_bg
    :border_color_urgent  theme.titlebar_bg
    :border_color_floating  theme.titlebar_bg
    :border_color_maximized  theme.titlebar_bg
    :border_color_fullscreen  theme.titlebar_bg

    ;; Corner Radius
    :border_radius  12
    
    ;; Edge snap
    :snap_bg  theme.xcolor8
    :snap_shape  (ui.rrect 0)
    
    ;; Main Menu
    :main_menu_bg  theme.lighter_xbackground

    ;; Tooltip
    :tooltip_bg  theme.lighter_xbackground
    :tooltip_fg  theme.xforeground
    :tooltip_font  (.. theme.font_name  "Regular 10")
              
    ;; Prompt
    :prompt-shape (ui.rrect 4) 
    
    
    ;; Hotkeys Pop Up
    :hotkeys_bg  theme.xbackground
    :hotkeys_fg  theme.xforeground
    :hotkeys_modifiers_fg  theme.xforeground
    :hotkeys_font  (.. theme.font_name  "Medium 12")
    :hotkeys_description_font  (.. theme.font_name  "Regular 10")
    :hotkeys_shape  (ui.rrect theme.border_radius)
    :hotkeys_group_margin  (dpi 50)
    :taglist_squares_sel  (theme_assets.taglist_squares_sel (dpi 0) theme.fg_normal)
    :taglist_squares_unsel  (theme_assets.taglist_squares_unsel (dpi 0) theme.fg_normal)
    
    ;; Tag preview
    :tag_preview_widget_margin  (dpi 10)
    :tag_preview_widget_border_radius  theme.border_radius
    :tag_preview_client_border_radius  (/ theme.border_radius 2)
    :tag_preview_client_opacity  1
    :tag_preview_client_bg  theme.wibar_bg
    :tag_preview_client_border_color  theme.wibar_bg
    :tag_preview_client_border_width  0
    :tag_preview_widget_bg  theme.wibar_bg
    :tag_preview_widget_border_color  theme.wibar_bg
    :tag_preview_widget_border_width  0
    
    ;; Layout List
    :layoutlist_shape_selected  (ui.rrect theme.border_radius)
    :layoutlist_bg_selected  theme.widget_bg
    
    
    ;; Gaps
    :useless_gap  (dpi 1)
    
    ;; Systray
    :systray_icon_size  (dpi 20)
    :systray_icon_spacing  (dpi 10)
    :bg_systray  theme.wibar_bg
    ;; theme.systray_max_rows  2

    ;; Tabs
    :mstab_bar_height  (dpi 60)
    :mstab_bar_padding  (dpi 0)
    :mstab_border_radius  (dpi 6)
    :mstab_bar_disable  true
    :tabbar_disable  true
    :tabbar_style  "modern"
    :tabbar_bg_focus  theme.xbackground
    :tabbar_bg_normal  theme.xcolor0
    :tabbar_fg_focus  theme.xcolor0
    :tabbar_fg_normal  theme.xcolor15
    :tabbar_position  "bottom"
    :tabbar_AA_radius  0
    :tabbar_size  0
    :mstab_bar_ontop  true
    
    ;; Notifications
    :notification_spacing  (dpi 4)
    :notification_bg  theme.xbackground
    :notification_bg_alt  theme.lighter_xbackground
    
    ;; Notif center
    :notif_center_notifs_bg  theme.one_bg2
    :notif_center_notifs_bg_alt  theme.one_bg3

    ;; Swallowing
    :dont_swallow_classname_list  { :firefox :gimp :Google-chrome :Thunar}
    ;; Layout Machi
    :machi_switcher_border_color  theme.lighter_xbackground
    :machi_switcher_border_opacity  0.25
    :machi_editor_border_color  theme.lighter_xbackground
    :machi_editor_border_opacity  0.25
    :machi_editor_active_opacity  0.25]) 
