(local list (require :utils.list))
(local {: root } (require :awesome-global)) 
(local screen-utils (require :utils.screen))
(local tag (require :tag))
(local create
       {:label "create-tag"
        :input-required true
        :input-prompt "Please input tag name"
        :exec #(tag.create 
                 {:name $1
                  :selected true})})
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

[create
 view-tag]
