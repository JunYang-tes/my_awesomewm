;; fennel-ls: macro-file
;;(import-macros {: css-gen } :css)
(fn css [...]
  (let [cls (string.gsub
              :cls_xxxxxxxx_xxxx_4xxx_yxxx_xxxxxxxxxxxx
              "[xy]"
              (fn [c]
                (let [v (if (= c :x)
                            (math.random 0 0xf)
                            (math.random 9 0xb))]
                  (string.format :%x v))))
        args [...]]
   `(let [content# (css-gen ,(.. "." cls) ,(table.unpack args))
          gtk4_css# (. (require :widgets) :gtk4_css)
          provider# (gtk4_css#.load_css content#)]
      (values ,cls provider#))))
(fn global-css [...]
  (let [cls (string.gsub
              :cls_xxxxxxxx_xxxx_4xxx_yxxx_xxxxxxxxxxxx
              "[xy]"
              (fn [c]
                (let [v (if (= c :x)
                            (math.random 0 0xf)
                            (math.random 9 0xb))]
                  (string.format :%x v))))
        args [...]]
   `(let [content# (css-gen ,(.. "." cls) ,(table.unpack args))
          gtk4_css# (. (require :widgets) :gtk4_css)
          provider# (gtk4_css#.load_css content#)]
      (values ,cls provider#))))
(fn global-id-css [id ...]
  (let [args [...]]
    `(let [content# (css-gen ,(.. "#" id) ,(table.unpack args))
           gtk4_css# (. (require :widgets) :gtk4_css)
           provider# (gtk4_css#.load_css content#)]
      (values ,id provider#))))
{
 : css
 : global-id-css
 : global-css}
 
