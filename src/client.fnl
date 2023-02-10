(local awful (require :awful))
(local awesome-global (require :awesome-global))
(local wm (require :utils.wm))
(local inspect (require :inspect))            
(local list (require :utils.list))
(local {: select-tag} (require :tag))
(local wibox (require :wibox))
(local tbl (require :utils.table))
(local screen-utils (require :utils.screen))
(local {: root } (require :awesome-global))
(local {: switch-tag} (require :tag))

(fn normalize-client [client]
  (if (or client.fullscreen client.maximized client.maximized_vertical client.maximized_horizontal) 
      (do
       (set client.fullscreen false) 
       (set client.maximized false) 
       (set client.maximized_vertical false) 
       (set client.maximized_horizontal false) 
       true) 
      false)) 

(fn move-chrome-devtools [client]
  (if (and 
        (= client.name :DevTools))
    (let [scs (length (screen-utils.get-screen-list))
          tag (list.find (root.tags) #(= $1.name "DevTool"))]
      (if (and 
            (not= nil tag)
            (> scs 1))
          (do
            (client:move_to_tag tag)
            (switch-tag tag))))))

(awesome-global.client.connect_signal :manage 
  (fn [client] 
    (move-chrome-devtools client)
    (local tag client.first_tag)
     ;; When a client exited,select a client in the same tag focus to it
    (client:connect_signal :unmanage 
                           (fn [] (wm.focus (wm.get-focusable-client tag))))
    (local clients (-> client 
                     (. :first_tag) 
                     (: :clients))) 

    (if (and (= client.type :normal)
             (not= client.role :prompt))
        (each [_ v (ipairs clients)]
              (normalize-client v))))) 

(awesome-global.client.connect_signal 
  "property::urgent"
  (fn [c]
    (tset c :minimized false)
    (c:jump_to)))
  

;; (awesome-global.client.connect_signal
;;   "request::titlebars"
;;   (fn [c]
;;     (-> c
;;       awful.titlebar
;;       (: :setup 
;;          (tbl.hybrid
;;            [
;;             (tbl.hybrid [(awful.titlebar.widget.iconwidget c)]
;;                         {:layout wibox.layout.fixed.horizontal})
;;             (tbl.hybrid [{:align :center
;;                           :widget (awful.titlebar.widget.titlewidget c)}]
;;               {:layout wibox.layout.flex.horizontal})] 
;;            {:layout wibox.layout.align.horizontal})))))
(awesome-global.client.connect_signal
  :focus (fn [client]
           (let [fullscreen client.fullscreen]
             ;; don't know why set ontop to true will close fullscreen
            (tset client :ontop true)
            (tset client :fullscreen fullscreen))))
(awesome-global.client.connect_signal
  :unfocus (fn [client]
            (tset client :ontop false)))
          

(fn focus-by-direction [dir]
  (let [ client awesome-global.client.focus
         clients (if client 
                     (client.first_tag:clients) 
                     [])] 
           
    (local geometry (. (awful.screen.focused ) :geometry))
    (if client 
        (wm.focus (wm.get-by-direct client clients dir geometry))))) 

(fn tag-untaged []
  (local untaged
    (-> (awesome-global.client.get)
      (list.filter (fn [c] (= c.first_tag nil)))))
  (if (> (length untaged) 0)
      (select-tag { :on-selected (fn [tag] 
                                   (-> untaged
                                       (list.map (fn [c] (c:move_to_tag tag)))))})))
      

{
 : normalize-client
 : focus-by-direction
 : tag-untaged} 
 
