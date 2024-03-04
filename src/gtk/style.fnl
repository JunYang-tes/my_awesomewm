(local {: Gtk } (require :lgi))

(fn apply [ctx]
  (let [css-provider (Gtk.CssProvider)]
    (css-provider:load_from_data """
                                   window {
                                    background-color: teal;
                                   }

                                   button {
                                    background: red;
                                   }
                                   """)
    (ctx:add_provider css-provider 600)))
    
{ : apply}
