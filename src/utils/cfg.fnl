(local {: filesystem } (require :gears))
(local cfg_path
  (.. (os.getenv "AWESOME_CONFIG")
      "/config/"))
(local json (require :cjson))

(fn load-cfg [name def]
  (local path (.. cfg_path name ".json"))
  (fn read []
    (let [(file msg) (io.open path "r")]
      (if file
          (do
            (fn decode [content]
              (let [(ok data) (pcall json.decode content)]
                (if ok
                    data
                    (do
                      (print :failed-to-parse content)
                      def))))
            (local cfg
              (-> file
               (: :read "*a")
               decode))
            (file:close)
            cfg)
          (do
            (print :failed-to-open-config)
            (print path)
            (print msg)
            def))))
  (if (filesystem.file_readable path)
      (read)
      def))

(fn save-cfg [cfg name]
  (local path (.. cfg_path name ".json"))
  (let [(file msg) (io.open path "w")]
    (if file
      (do
        (-> cfg
            json.encode
            file:write)
        (file:close))
      (do
        (print :failed-to-write path)
        (print msg)))))

{ : load-cfg
  : save-cfg}
