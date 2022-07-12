(local awful (require :awful))

(local screens [])

(fn key-screen [screen]
  (screen.outputs )) 

(awful.screen.connect_for_each_screen #(table.insert screens $1))
(awful.screen.disconnect_for_each_screen #(remove-value! screens $1))
