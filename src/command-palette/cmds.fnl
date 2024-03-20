(local list (require :utils.list))
(local fzy (require :fzy))
(local fuzzy-matcher ((. (require :widgets) :matcher :matcher)))
(local {: assign } (require :utils.table))
(local inspect (require :inspect))

(fn fuzzy [pattern list]
  (fuzzy-matcher:sort list pattern))

(fn split-input [input]
  (let [(index) (or (string.find input " ") (values 0))]
    (if (> index 0)
        [(string.sub input 1 (- index 1)) (string.sub input (+ index 1))]
        [input ""])))

(fn markup [str pos]
  (let [parts []]
    (for [i  1 (length str)]
      (let [v (str:sub i i)]
        (if (= i (. pos 1))
          (do (table.insert parts (.. "<u>" v "</u>"))
              (table.remove pos 1))
          (table.insert parts v))))
    (table.concat parts)))

(fn assert-is-a-cmd [obj]
  (let [is-a-cmd
         (and (= (type obj) :table)
              (= (type obj.label) :string)
              (= (type obj.exec) :function))]
    (assert is-a-cmd :not-a-cmd)))

(local commands
  (let [cmds {}]
    {:register (fn [cmd]
                  (table.insert cmds cmd))
     :cmds (fn [] cmds)
     :create-command-mgr (fn [commands]
                            (let [state {:commands (or commands cmds)
                                         :commands-stack []}]

                                (fn push [cmds]
                                  (table.insert state.commands-stack cmds))
                                (fn pop []
                                  (table.remove state.commands-stack))
                                (fn clean []
                                  (tset state :commands-stack []))
                                (fn current-commands []
                                  (let [size (length state.commands-stack)]
                                    (if (> size 0)
                                      (. state.commands-stack size)
                                      state.commands)))
                                (fn is-cmdstack-empty []
                                  (= (length state.commands-stack) 0))

                                {:register (fn [cmd]
                                              (table.insert state.commands cmd))
                                 ;; return :close | :keep-open | :has-sub
                                 :run (fn [cmd input]
                                        (assert-is-a-cmd cmd)
                                        (if cmd.input-required
                                          (assert (not= nil input) :input-is-required))
                                        (let [r (cmd.exec input)
                                              r
                                                (match r
                                                  :keep-open :keep-open
                                                  nil :close
                                                  (where sub-cmds (list.is-list sub-cmds))
                                                  (do (push r)
                                                    :has-sub)
                                                  _ :close)]
                                          (if (= r :close)
                                              (clean))
                                          r))
                                 : is-cmdstack-empty
                                 : pop
                                 :reset (fn [] (clean))
                                 :cmds (fn [] (current-commands))
                                 :match (fn [input]
                                          (let [[ input ] (split-input (string.lower input))
                                                cmds (current-commands)]
                                            (if input
                                              (-> input
                                                  (fuzzy (list.map cmds (fn [cmd] cmd.label)))
                                                  (list.map (fn [item] (let [label (. item 1)
                                                                             indexes (. item 2)
                                                                             index (. item 3)

                                                                             cmd (. cmds index)]
                                                                         (assign cmd
                                                                                 {:label (markup cmd.label indexes)})))))
                                              cmds)))}))}))


{: commands
 :register commands.register}
 
