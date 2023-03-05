(local {: spawn} (require :awful))

;; run cmds in config/autorun
;; each line is a cmd
(let [(ok cmds) (pcall 
                  #(with-open [in (io.open
                                    (.. (os.getenv :AWESOME_CONFIG)
                                        "/config/autorun") )]
                          (icollect [i v (in:lines)] i)))]
  (when ok
    (each [_ cmd (ipairs cmds)]
      (print cmd)
      (spawn cmd))))
