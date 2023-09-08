(local awful (require :awful))
(local wibox (require :wibox))
(local {: hybrid} (require :utils.table))
(local inspect (require :inspect))
(local gears (require :gears))
(local {: focus} (require :utils.wm))

(fn [client]
  (let [buttons (gears.table.join
                  (awful.button [] 1 (fn []
                                       (focus client)
                                       (client:raise)
                                       (awful.mouse.client.move client)))
                  (awful.button [] 3 (fn []
                                       (focus client)
                                       (client:raise)
                                       (awful.mouse.client.resize client))))
        bar (awful.titlebar client)
        widget (hybrid [(hybrid [(awful.titlebar.widget.iconwidget client)]
                              {: buttons :layout wibox.layout.fixed.horizontal})
                        (hybrid [{:halign :center
                                  :widget (awful.titlebar.widget.titlewidget client)}]
                                {: buttons :layout wibox.layout.fixed.horizontal})
                        (hybrid [(awful.titlebar.widget.maximizedbutton client)
                                 (awful.titlebar.widget.closebutton client)]
                                { :layout wibox.layout.fixed.horizontal})]
                       {:layout wibox.layout.align.horizontal})]

    (bar:setup widget)
    bar))
