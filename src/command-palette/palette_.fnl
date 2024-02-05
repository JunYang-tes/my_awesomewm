(import-macros {: unmount : defn : effect} :lite-reactive)
(import-macros {: css-gen } :css)
(import-macros {: global-css : css
                : global-id-css } :gtk)
(import-macros {: catch-ignore : catch} :utils)
(local {: run
        : use-built
        : foreach} (require :lite-reactive.app))
(local {: window
        : box
        : label
        : list-box
        : list-row
        : scrolled-window
        : entry} (require :gtk_.node))
(local consts (require :gtk_.const))
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
(local xresources (require :beautiful.xresources))
(local dpi xresources.apply_dpi)
;; Command = {
;;  label: string
;;  real-time?: (arg:string)=>string
;;  description?: string
;;  exec: (input:string) => Command[] | "keep-open" | any
;; }
;;

(fn px [num]
  (.. (dpi num) "px"))
(fn split-input [input]
  (let [(index) (or (string.find input " ") (values 0))]
    (if (> index 0)
        [(string.sub input 1 (- index 1)) (string.sub input (+ index 1))]
        [input ""])))

(local win-css (global-css
                 [:background :#111828
                  :color :white]
                 (& " *"
                    [:background :transparent
                     :color :white
                     :outline-width :0])
                 (& " entry"
                    (& ":focus"
                       [:border "2px solid #111828"
                        :border-bottom "1px solid #CCC"
                        :-gtk-outline-top-right-radius :20px])
                    [
                     :font-size (px 16)
                     :box-shadow :none
                     :border "2px solid #111828"
                     :border-bottom "1px solid #CCC"
                     :padding   (px 10)])
                 (& " .cmd-label"
                    [:font-size (px 16)
                     :margin-bottom (px 4)])
                 (>> ".cmd-desc"
                     [:font-size (px 12)])
                 (& " row"
                    [:padding (px 4)]
                    (> "box"
                      [:padding (px 4)
                       :padding-left (px 10)])
                    (& ".selected"
                       (> "box"
                          [:border-radius (px 8)
                           :background "#202938"])))
                 (>> ".tips"
                     [:padding (px 4)])))

;; (defn command-item
;;       (box))
(defn pallet-node
  (local win nil)

  (let [{: visible
         : close} props
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
        ; close (fn [win-node]
        ;         (win-node:close)
        ;         (selected-index 1)
        ;         (input "")
        ;         (visible false))
        handle-esc (fn []
                     (print :ESC close)
                     (if (not (command-mgr.is-cmdstack-empty))
                         (do
                           (command-mgr.pop)
                           (refresh-cmds))
                         ((close))))
        run (fn [current-text]
              (let [[cmd args] (split-input current-text)
                    result (command-mgr.run (selected-cmd) args)]
                (match result
                  :close ((close))
                  :has-sub (do
                             (input "")
                             (refresh-cmds))
                  :keep-open (input cmd))))
        top-cmds (map cmds (fn [cmds]
                             (if (> (length cmds)
                                    200)
                               (table.move cmds 1 200 1 {})
                               cmds)))
        cmd_input (entry
                   {
                    :connect_map (fn [entry]
                                   (: entry :grab_focus))
                    :connect_key_release_event
                     (fn [w e]
                       (let [keyval (-> e
                                        (: :keyval)
                                        (: :to_unicode))
                             keys consts.Keys
                             control (= (-> e
                                           (: :state)
                                           (band consts.Modifier.Control)) 
                                        consts.Modifier.Control)]
                         (if control
                           (match keyval
                             keys.j (inc-selected-index)
                             keys.k (dec-selected-index))
                           (catch-ignore
                             ""
                             (match keyval
                               keys.enter (run (: w :text))
                               keys.esc (handle-esc)
                               _ (input (: w :text)))))))
                     :text input})
        cmd-items (map-list
                    top-cmds
                    (fn [cmd]
                      (list-row
                        {:class (map selected-cmd
                                     (fn [item]
                                       (if (= cmd item)
                                         "selected"
                                         "")))
                         :connect_focus_in_event (fn []
                                                   (let [input-widget (cmd_input)]
                                                     (input-widget:grab_focus)))}
                        (box
                          {:orientation consts.Orientation.VERTICAL}
                          (label
                            {:markup cmd.label
                             :class "cmd-label"
                             :xalign 0})
                          (let [desc (map input
                                          (fn [input]
                                            (let [[_ args] (split-input input)]
                                              (if cmd.real-time
                                                (catch "" ""
                                                       (cmd.real-time args))
                                                (or cmd.description "")))))]
                            (label
                              {:label desc
                               :class "cmd-desc"
                               :visible (map desc (fn [desc]
                                                    (if (and desc
                                                             (> (length desc) 0))
                                                       true
                                                       false)))
                               :wrap true
                               :xalign 0}))))))
        list (list-box cmd-items)
        on-built (use-built)
        win
        (window
          {
           : visible
           :class win-css
           :role :prompt
           :connect_focus_out_event close}
          (box
            {:orientation consts.Orientation.VERTICAL}
            cmd_input
            (scrolled-window
              {:-expand true
               :class (css [:min-height :400px])
               :-fill true}
              list)
            (box
              {:class :tips}
              (label {:-fill true :-expand true})
              (label {:label "󰜷 Ctrl+K "})
              (label {:label "󰜮 Ctrl+J "})
              (label {:label (map cmds #(.. "󰘳 " (length $1)))}))))]
              ; (box
              ;   {:orientation Gtk.Orientation.VERTICAL}
              ;   cmd-items))))]
    (effect [selected-index]
      (when (on-built)
        (let [index (- (selected-index) 1)
              list (list)
              row (list:row_at_index index)]
          (list:select_row row)
          (row:grab_focus) ;;let it scroll to this row
          (: (cmd_input) :grab_focus))))
    (effect [visible]
      (refresh-cmds))
    win))

(var running nil)
{
 :run (fn [cmds]
        (if running
          (running.close)
          (let [mgr (commands.create-command-mgr cmds)
                visible (value false)]
            (var win nil)
            (local close (fn []
                           (set running nil)
                           (win:close)))
            (set win (run (pallet-node
                              {: visible
                               : close
                               : mgr})))
            (set running {: close})
            (visible true))))}

