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
{: add
 : remove}
