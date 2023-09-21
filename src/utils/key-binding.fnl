(local {: filter} (require :utils.list))
(local gears (require :gears))
(fn add [key]
  (let [root _G.root
        keys (root.keys)]
    (root.keys 
      (gears.table.join keys key))))
    ; (table.insert keys key)
    ; (print keys)))
    ;;(root.keys keys)))

(fn remove [key]
  (let [root _G.root
        keys (root.keys)]
    (table.remove keys key)
    (root.keys keys)))

(fn add-mouse [key]
  (let [root _G.root
        keys (root.buttons)]
    (print :add-mouse-button)
    (root.buttons
      (gears.table.join key))))
(fn remove-mouse [key]
  (let [root _G.root
        keys (root.buttons)]
    (root.buttons
      (filter keys
              #(not= key $1)))))

{: add
 : remove
 : add-mouse
 : remove-mouse}
