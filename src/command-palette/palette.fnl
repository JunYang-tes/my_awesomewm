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
        : map-list
        : map
        : mapn} (require :lite-reactive.observable))
(local inspect (require :inspect))
(local keys (require :gtk.keyval))
(local fzy (require :fzy))
(local {: assign } (require :utils.table))
(local {: commands
        : register } (require :command-palette.cmds))
;; Command = {
;;  label: string
;;  real-time?: (arg:string)=>string
;;  description?: string
;;  exec: (input:string) => Command[] | "keep-open" | any
;; }
;;

(fn split-input [input]
  (let [(index) (or (string.find input " ") (values 0))]
    (if (> index 0)
        [(string.sub input 1 (- index 1)) (string.sub input (+ index 1))]
        [input ""])))

(local selected-cmd-css (global-css [:color :red]))
(local unselected-cmd-css (global-css [:color :green]))
(local entry-css (global-css [:font-size :36px]))
;; (defn command-item
;;       (box))
(defn pallet-node
  (let [{: visible} props
        command-mgr (props.mgr)
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
                     (if (not (command-mgr.is-cmdstack-empty))
                         (do
                           (command-mgr.pop)
                           (refresh-cmds))
                         (close)))
        run (fn [current-text]
              (let [[cmd args] (split-input current-text)
                    result (command-mgr.run (selected-cmd) args)]
                (match result
                  :close (close)
                  :has-sub (do
                             (input "")
                             (refresh-cmds))
                  :keep-open (input cmd))))
        item-cls (css [:border-bottom "1px solid #ccc"
                       :padding-left :8px])
        top-cmds (map cmds (fn [cmds]
                             (if (> (length cmds)
                                    20)
                               (table.move cmds 1 20 1 {})
                               cmds)))
        cmd-items (map-list top-cmds
                    (fn [cmd]
                      (box
                        {:orientation Gtk.Orientation.VERTICAL
                         :class item-cls}
                        (label
                          {:markup cmd.label
                           :xalign 0
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
                                            (or cmd.description "")))))
                           :wrap true
                           :xalign 0}))))
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
                 (if e.state.CONTROL_MASK
                   (match e.keyval
                     keys.j (inc-selected-index)
                     keys.k (dec-selected-index)))
                 (catch-ignore
                   ""
                   (match e.keyval
                     keys.enter (run w.text)
                     keys.esc (handle-esc)
                     _ (input w.text))))
               :text input})
            (label {:label (map cmds #(.. "Commands:" (length $1)))})
            (scrolled-window
              {:-expand true
               :class (css [:min-height :400px])
               :-fill true}
              (box
                {:orientation Gtk.Orientation.VERTICAL}
                cmd-items))))]
    (effect [visible]
      (refresh-cmds))
    win))

{
 :run (fn [cmds]
        (let [mgr (commands.create-command-mgr cmds)
              visible (value false)]
          (run (pallet-node
                 {: visible
                  : mgr}))
          (visible true)))}

