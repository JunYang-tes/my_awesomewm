(import-macros {: unmount : defn : effect} :lite-reactive)
(import-macros {: css-gen } :css)
(import-macros {: global-css : css } :gtk)
(import-macros {: catch-ignore : catch} :utils)
(local {: Gtk } (require :lgi))
(local {: run
        : foreach} (require :lite-reactive.app))
(local {: window
        : box
        : label
        : list-box
        : scrolled-window
        : entry} (require :gtk.node))
(local list (require :utils.list))
(local stringx (require :utils.string))
(local {: value
        : map
        : mapn} (require :lite-reactive.observable))
(local inspect (require :inspect))
(local keys (require :gtk.keyval))
;; Command = {
;;  label: string
;;  real-time?: (arg:string)=>string
;;  input-required: bool
;;  input-prompt: string
;;  exec: (input:string) => Command[] | nil
;; }
;;

(fn split-input [input]
  (let [(index) (or (string.find input " ") (values 0))]
    (if (> index 0)
        [(string.sub input 1 (- index 1)) (string.sub input (+ index 1))]
        [input ""])))
(fn assert-is-a-cmd [obj]
  (let [is-a-cmd
         (and (= (type obj) :table)
              (= (type obj.label) :string)
              (= (type obj.exec) :function))]
    (assert is-a-cmd :not-a-cmd)))
(local command-mgr
  (let [state {:commands []
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
                  (print :register cmd.label)
                  (table.insert state.commands cmd))
     :run (fn [cmd input]
            (assert-is-a-cmd cmd)
            (if cmd.input-required
              (assert (not= nil input) :input-is-required))
            (let [r
                  (cmd.exec input)]
              (if (list.is-list r)
                  (do
                    (push r)
                    r)
                  (clean))))
     : is-cmdstack-empty 
     : pop
     :reset (fn [] (clean))
     :match (fn [input]
              (let [[ input ] (split-input (string.lower input))]
                (list.filter (current-commands)
                  #(stringx.includes (string.lower $1.label) input))))}))

(local selected-cmd-css (global-css [:color :red]))
(local unselected-cmd-css (global-css [:color :green]))
(local entry-css (global-css [:font-size :36px]))
;; (defn command-item
;;       (box))
(defn pallet-node
  (let [{: visible} props
        pending-cmd (value nil) ;; a cmd which is waiting input
        has-pending-cmd (fn [] (not= nil (pending-cmd)))
        selected-index (value 1)
        input (value "")
        cmds (map input #(command-mgr.match (input)))
        refresh-cmds (fn []
                       (cmds (command-mgr.match (input))))
        selected-cmd (mapn [selected-index cmds]
                        (fn [[idx cmds]]
                          (or (. cmds idx)
                              (. cmds 1))))
        inc-selected-index #(let [cmds-count (length (cmds))
                                  idx (+ (selected-index) 1)]
                                (selected-index
                                  (if (> idx cmds-count) 
                                      1
                                      idx)))
        dec-selected-index #(let [cmds-count (length (cmds))
                                  idx (- (selected-index ) 1)]
                              (selected-index
                                (if (< idx 1)
                                  cmds-count
                                  idx)))
        close (fn [win-node]
                (selected-index 1)
                (input "")
                (visible false))
        handle-esc (fn []
                     (if (has-pending-cmd)
                         (pending-cmd.set nil)
                         (not (command-mgr.is-cmdstack-empty )) (command-mgr.pop)
                         (close)))
        run-pending-cmd (fn [input]
                          (let [cmd (pending-cmd)
                                r (command-mgr.run cmd input)]
                           (pending-cmd.set nil)
                           (if (= nil r)
                               (close)
                               (do 
                                 (input "")
                                 (refresh-cmds)))))
        run-cmd (fn [cmd]
                  (if cmd.input-required
                      (do
                        (input "")
                        (pending-cmd cmd))
                      (let [result (command-mgr.run cmd)]
                        (print :cmd-result result)
                        (if (= nil result)
                            (close)
                            (do
                              (input "")
                              (refresh-cmds))))))
        run (fn [current-text]
              (if (has-pending-cmd)
                  (run-pending-cmd current-text)
                  (run-cmd (selected-cmd))))
        item-cls (css [:border-bottom "1px solid #ccc"])
        win
        (window
          {:keep-alive true
           : visible
           :role :prompt
           :on_focus_out_event #(close win)}
          (box
            {:orientation Gtk.Orientation.VERTICAL}
            (entry 
              {:on_parent_set #(: $1 :grab_focus)
               :class [entry-css]
               :on_key_release_event
               (fn [w e]
                 (print e.keyval (inspect e.state))
                 (if e.state.CONTROL_MASK
                   (match e.keyval
                     keys.j (inc-selected-index)
                     keys.h (dec-selected-index)))
                 (catch-ignore
                   ""
                   (match e.keyval
                     keys.enter (run w.text)
                     keys.esc (handle-esc)
                     _ (input w.text))))
               :text input})
            (map pending-cmd
              (fn [pending-cmd]
                (if (= nil pending-cmd)
                  (scrolled-window
                    {:-expand true
                     :class (css [:min-height :400px])
                     :-fill true}
                    (box
                      {:orientation Gtk.Orientation.VERTICAL}
                      (foreach cmds 
                        (fn [cmd]
                          (box
                            {:orientation Gtk.Orientation.VERTICAL
                             :class item-cls} 
                            (label 
                              {:label (map selected-cmd
                                           (fn [item] 
                                            (if (= cmd item)
                                              (.. ">" cmd.label)
                                              (.. " " cmd.label))))
                               :halign Gtk.Align.LEFT
                               :class (map selected-cmd 
                                           (fn [item]
                                              (if (= cmd item)
                                                  selected-cmd-css
                                                  "")))})
                            (label
                              {:label (map input
                                        (fn [input]
                                          (let [[_ args] (split-input input)]
                                            (if cmd.real-time
                                                (catch "" ""
                                                  (cmd.real-time args))
                                                "")))) 
                               :halign Gtk.Align.LEFT}))))))
                  (label {:label pending-cmd.input-prompt}))))))]
    (effect [visible]
      (refresh-cmds))
    win))

(local palette 
  (let [visible (value false)]
    (run (pallet-node {: visible}))
    {:show (fn [] (visible true))}))

{
 :register command-mgr.register
 :run (fn [] (palette.show))}
 
