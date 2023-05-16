(local {: register} (require :command-palette.cmds))
(local tag-cmds (require :command-palette.tag))
(local awesome-cmds (require :command-palette.awesome))
(local tools (require :command-palette.tools))
(local system (require :command-palette.system))
(local volumn-cmds (require :command-palette.volumn))
(local inspect (require :inspect))
(local apps (require :command-palette.applications))
(local {: is-list} (require :utils.list))

(fn load [cmds]
  (if (is-list cmds)
    (each [_ i (ipairs cmds)]
      (register i))
    (each [_ v (pairs cmds)]
      (register v))))

(load tag-cmds)
(load awesome-cmds)
(load tools)
(load system)
(load volumn-cmds)
(load apps)
(load (require :command-palette.bookmark))
