(local {: Gtk
        : GObject } (require :lgi))
(local {: window
        : label
        : box
        : entry} (require :gtk.node))
(local model (Gtk.ListStore.new [GObject.Type.STRING]))
(local {: run } :lite-reactive.app)
(model:append [:GNOME])
(model:append [:Lua])
(model:append [:LGI])
(model:append [:GTK])
(model:append [:Example])
(local completion (Gtk.EntryCompletion {: model :text_column 0 :popup_completion true}))

(local r (require :lite-reactive.observable))
(local text (r.value ""))
(run (window 
      (box
        {:orientation Gtk.Orientation.VERTICAL
         :halign Gtk.Align.CENTER
         :valign Gtk.Align.CENTER}
        (entry {:text text 
                :completion completion
                :on_key_release_event #(text.set (. $1 :text))})
        (entry {:text text :on_key_release_event #(text.set (. $1 :text))})
        (label {:text (r.map text #(.. "length:" (length $1)))}))))
