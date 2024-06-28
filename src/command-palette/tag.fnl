(local awful (require :awful))
(local list (require :utils.list))
(local {: root } (require :awesome-global)) 
(local {: normalize-client } (require :client)) 
(local screen-utils (require :utils.screen))
(local tag (require :tag))
(local create
       {:label "Create tag"
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

(fn tag-name [tag]
  (or tag.name 
      "Anonymous"))

(local view-tag
       {:label "View tag"
        :exec (fn []
                (tag-cmd #(.. "View " (tag-name $1) "(" (screen-utils.get-name $1.screen)  ")")
                         (fn [t]
                           (fn [] (tag.switch-tag t)))))})
(local delete-tag
  {:label "Delete tag"
   :exec (fn []
           (tag-cmd #(.. "Delete " (tag-name $1) "(" (screen-utils.get-name $1.screen) ")")
                    (fn [t]
                      (fn [] (t:delete)))))})
(local move-to-tag
  {:label "Move to tag"
   :exec (fn []
           (tag-cmd #(.. "Move windown to " (tag-name $1) "(" (screen-utils.get-name $1.screen) ")")
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
       {:label "Swap tag"
        :exec (fn []
                (local current (-> (awful.screen.focused)
                                   (. :selected_tag))) 
                (tag-cmd #(.. "Swap " current.name " with " (tag-name $1)))
                (fn [t]
                  (fn []
                    (current:swap t))))})
(local move-tag-to-screen
       {:label "Move tag to screen"
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
       {:label "Rename tag"
        :real-time #(.. "Rename " (tag-name (wm.get-current-tag) ) " to: " $1)
        :exec (fn [input]
                (tset (wm.get-current-tag) :name input))})
(local delete-unnamed-tag
  {:label "Delete unnamed tag"
   :exec (fn []
           (-> (_G.root.tags)
               (list.filter #(and (or
                                    (= $1.name nil)
                                    (= $1.name :Default)
                                    (= $1.name :Anonymous))
                                  (= (length ($1:clients)) 0)))
               (list.foreach #(do
                                ($1:delete))))
           (tag.save-tags))})
{: create
 : view-tag
 : delete-tag
 : delete-unnamed-tag
 : move-to-tag
 : move-tag-to-screen
 : swap-tag
 : rename-tag}
