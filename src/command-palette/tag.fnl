(local awful (require :awful))
(local list (require :utils.list))
(local {: root } (require :awesome-global)) 
(local {: normalize-client } (require :client)) 
(local screen-utils (require :utils.screen))
(local tag (require :tag))
(local create
       {:label "create-tag"
        :input-required true
        :input-prompt "Please input tag name"
        :exec #(tag.create 
                 {:name $1
                  :selected true})})
(local wm (require :utils.wm))
(fn tag-cmd [tag-label tag-action]
  (list.map
    (root.tags)
    (fn [tag]
      {:label (tag-label tag)
       :exec (tag-action tag)})))

(local view-tag
       {:label "view-tag"
        :exec (fn []
                (tag-cmd #(.. "View " $1.name "(" (screen-utils.get-name $1.screen)  ")")
                         (fn [t]
                           (fn [] (tag.switch-tag t)))))})
(local move-to-tag
  {:label "move-to-tag"
   :exec (fn []
           (tag-cmd #(.. "Move windown to " $1.name "(" (screen-utils.get-name $1.screen) ")")
                    (fn [t]
                      (fn []
                        (let [s (awful.screen.focused)
                              client (awful.client.focus.history.get s 1)]
                          (tag.switch-tag t)
                          (client:move_to_tag t)
                          (wm.focus client)
                          (each [_ c (ipairs (t:clients))]
                            (normalize-client c)))))))})
(local swap-tag
       {:label "swap-tag"
        :exec (fn []
                (local current (-> (awful.screen.focused)
                                   (. :selected_tag))) 
                (tag-cmd #(.. "Swap " current.name " with " $1.name))
                (fn [t]
                  (fn []
                    (current:swap t))))})
(local move-tag-to-screem
       {:label "move-tag-to-screem"
        :exec (fn []
                (local screens 
                       (icollect [ k v (pairs (screen-utils.get-screens))]
                         v)) 
                (match (length screens)
                  0 nil
                  1 nil
                  2 (tag.move-to-another-screen)
                  _ (list.map screens 
                              (fn [screen]
                                {:label (.. "Move current tag to " (screen-utils.get-name))
                                 :exec (fn []
                                         (let [current (wm.get-current-tag)]
                                           (set current.screen screen)))}))))})
(local rename-tag
       {:label "rename-tag"
        :real-time #(.. "Rename " (. (wm.get-current-tag) :name) " to: " $1)
        :exec (fn [input]
                (tset (wm.get-current-tag) :name input))})
[create
 view-tag
 move-to-tag
 move-tag-to-screem
 swap-tag
 rename-tag]
