(local {: register} (require :command-palette.palette))
(local tag-cmds (require :command-palette.tag))
(local awesome-cmds (require :command-palette.awesome))
(local tools (require :command-palette.tools))
(local inspect (require :inspect))
(fn load [cmds]
  (each [_ i (ipairs cmds)]
    (print :load i.label)
    (register i)))

(load tag-cmds)
(load awesome-cmds)
(load tools)
