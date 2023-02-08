(local {: register} (require :command-palette.palette))
(local tag-cmds (require :command-palette.tag))
(local awesome-cmds (require :command-palette.awesome))
(local tools (require :command-palette.tools))
(local system (require :command-palette.system))
(local volumn-cmds (require :command-palette.volumn))
(local inspect (require :inspect))
(fn load [cmds]
  (each [_ i (ipairs cmds)]
    (print :load i.label)
    (register i)))

(load tag-cmds)
(load awesome-cmds)
(load tools)
(load system)
(load volumn-cmds)
