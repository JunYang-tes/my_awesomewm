(local {: Gtk
        : GObject } (require :lgi))
(local {: window
        : label
        : box
        : entry} (require :gtk.widgets))
(local model (Gtk.ListStore.new [GObject.Type.STRING]))
(model:append [:GNOME])
(model:append [:Lua])
(model:append [:LGI])
(model:append [:GTK])
(model:append [:Example])
(local completion (Gtk.EntryCompletion {: model :text_column 0 :popup_completion true}))

(local r (require :gtk.observable))
(local text (r.value ""))
(local win (window 
            (box
              {:orientation Gtk.Orientation.VERTICAL
               :halign Gtk.Align.CENTER
               :valign Gtk.Align.CENTER}
              (entry {:text text 
                      :completion completion
                      :on_key_release_event #(text.set (. $1 :text))})
              (entry {:text text :on_key_release_event #(text.set (. $1 :text))})
              (label {:text (r.map text #(.. "length:" (length $1)))}))))
(win:show_all)
