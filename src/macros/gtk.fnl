;;(import-macros {: css-gen } :css)
(fn css [...]
  (let [cls (string.gsub
              :xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
              "[xy]"
              (fn [c]
                (let [v (if (= c :x)
                            (math.random 0 0xf)
                            (math.random 9 0xb))]
                  (string.format :%x v))))
              
        args [...]]
   `(let [content# (css-gen ,(.. "." cls) ,(table.unpack args))
          {:Gtk Gtk# :Gdk Gdk#} (require :lgi)
          provider# (Gtk#.CssProvider)]
                   
      (provider#:load_from_data content#)
      (Gtk#.StyleContext.add_provider_for_screen
        (Gdk#.Screen.get_default)
        provider#
        Gtk#.STYLE_PROVIDER_PRIORITY_USER)
      (unmount
        (Gtk#.StyleContext.remove_provider_for_screen
          (Gdk#.Screen.get_default)
          provider#))
      ,cls)))

{
 : css}
 
