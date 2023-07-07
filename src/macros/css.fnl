;; fennel-ls: macro-file
(fn css-gen [cls ...]
  (local connectors 
         {:& ""
          "" ""
          :+ "+"
          :> ">"
          :>> " "
          "~" "~"
          "+" "+"})
  (fn css-rule [k v]
    (match (values (type k) (type v))
      (:string :string)
      (.. k ":" v ";\n")

      (:string _)
      (let [a (.. k ":")]
         `(.. ,a ,v ";\n"))

      (_ :string)
      (let [a (.. v ";\n")]
        `(.. ,k ":" a))

      (_ _) 
      `(.. k ":" v ";\n")))
  (fn css-block [ls]
    (let [rules []]
      (for [i 1 (length ls) 2]
        (let [k (. ls i)
              v (. ls (+ i 1))]
          (table.insert rules (css-rule k v))))
      (let [result
            (accumulate [result {:collected [] 
                                 :rules []}
                         _ item (ipairs rules)]
              (do
                (if (= (type item) :string)
                  (table.insert result.collected item)
                  (> (length result.collected) 0) 
                  (do 
                    (table.insert result.rules (table.concat result.collected))
                    (tset result :collected [])
                    (table.insert result.rules item))
                  (table.insert result.rules item))
                result))]
        (if (> (length result.collected) 0)
            (table.insert result.rules (table.concat result.collected)))
        `(.. "{\n" (table.concat ,result.rules "\n")
             "}\n"))))
  (fn flat [ls]
    (let [r []]
      (each [_ item (ipairs ls)]
        (each [_ sub-item (ipairs item)]
          (table.insert r sub-item)))
      r))
  (fn concat-selector [selector block]
    (match (values (type selector) (type block))
      (:string :string) (.. selector block)
      (_ _)  `(.. ,selector ,block)))

  (fn prepare-connector [connector]
    (let [c (if (sym? connector)
                (. connector 1)
                (= (type connector) :string)
                connector
                (error "Expect sym or string "))
          c (. connectors c)]
      (if (= nil c)
          (error (.. "Expect one of &,+,>,>>,~,+, Got" connector)))
      c))
  (fn make-selector [selector connector sub-selector]
    (let [connector (prepare-connector connector)]
      (match (values (type selector) (type sub-selector))
        (:string :string) (.. selector connector sub-selector)
        (:string _) (let [a (.. selector connector)]
                      `(.. ,a ,sub-selector))
        (_ :string) (let [a (.. connector sub-selector)]
                      `(.. ,selector ,a))
        _ `(.. ,selector ,connector ,sub-selector))))
  (fn gen [selector connector sub-selector ...]    
    (let [selector (make-selector selector connector sub-selector)
          {: rules : blocks } (accumulate [acc {:rules [] :blocks []}
                                           _ item (ipairs [...])]
                               (do
                                 (if (sequence? item)
                                     (table.insert acc.rules item)
                                     (list? item)
                                     (table.insert acc.blocks item)
                                     (error "Unexpected element"))
                                 acc))
          rules (flat rules)
          css-text [(concat-selector selector (css-block rules))]]
      (each [_ item (ipairs blocks)]
        (let [
              [connector sub-selector & rest] item]
          (table.insert css-text (gen selector connector sub-selector (table.unpack rest))))) 
      (let [result (accumulate [acc {:collected [] :blocks []}
                                _ item (ipairs css-text)]
                     (do 
                       (if (= (type item) :string)
                           (table.insert acc.collected item)
                           (> (length acc.collected) 0)
                           (do 
                             (table.insert acc.blocks (table.concat acc.collected "\n"))
                             (tset acc :collected [])
                             (table.insert acc.blocks item))
                           (table.insert acc.blocks item))
                       acc))]
        (if (> (length result.collected) 0)
            (table.insert result.blocks (table.concat result.collected "\n")))
        (if (= (length result.blocks) 1)
            (. result.blocks 1)
            (> (length result.blocks) 1)
            `(table.concat ,result.blocks "\n")))))
  (gen cls "" "" ...))
  ;; (let [cls :.test
  ;;       content (gen cls "" "" ...)]
  ;;   `(let [{:Gtk Gtk# :Gdk Gdk#} (require :lgi)
  ;;          provider# (Gtk#.CssProvider)]
  ;;      (provider#:load_from_data ,content)
  ;;      (Gtk#.StyleContext.add_provider_for_screen 
  ;;        (Gdk#.Screen.get_default)
  ;;        provider#
  ;;        Gtk#.STYLE_PROVIDER_PRIORITY_USER)
  ;;      cls)))

{ 
  : css-gen}
