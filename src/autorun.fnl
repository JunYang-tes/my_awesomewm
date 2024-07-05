(local {: spawn} (require :awful))
(local {: read-popen} (require :utils.process))
(local list (require :utils.list))
(local strx (require :utils.string))
; (local {: launcher 
;         : fs} (require :widgets))

; (fn run-desktop [path]
;   (-> (fs.dir path)
;       (list.filter #(strx.ends-with $1 ".desktop"))
;       (list.foreach #(launcher.launch_desktop_file $1))))

;; run cmds in config/autorun
;; each line is a cmd
(let [(ok cmds) (pcall 
                  #(with-open [in (io.open
                                    (.. (os.getenv :AWESOME_CONFIG)
                                        "/config/autorun"))]
                          (icollect [i v (in:lines)] i)))]
  (when ok
    (each [_ cmd (ipairs cmds)]
      (spawn cmd))))
;(run-desktop (.. (os.getenv "HOME") "/.config/autostart/"))
