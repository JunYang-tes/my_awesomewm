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
        
        ;: list-box
        : list-view
        : picture
        ;: list-row
        : scrolled-window
        : entry} (require :gtk4.node))
(local consts (require :gtk4.const))
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
(local {: debounce} (require :utils.timer))
;; Command = {
;;  label: string
;;  real-time?: (arg:string)=>string
;;  description?: string
;;  image? ImageSurface | string
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
                 (& " .cmd-item"
                    [:min-height (px 38)
                     :padding (.. (px 2) " " (px 8))
                     :border-radius (px 8)])
                 (& " .selected"
                    [:background-color "#202938"])
                 ; (& " .image"
                 ;    [:border "1px solid red"])
                 (& " .labels"
                    [:margin-left (px 10)])
                 (& " .cmd-label"
                    [:font-size (px 16)
                     :margin-bottom (px 4)])
                 (>> ".cmd-desc"
                     [:font-size (px 12)])
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
                             (input ""))
                             ;(refresh-cmds))
                  :keep-open (input cmd))))
        cmd_input (entry
                   {
                    :connect_map (fn [entry]
                                   (entry:grab_focus))
                    :connect_change  
                                 (fn [new-text]
                                   (input new-text)
                                  200)
                    :connect_key_pressed_capture 
                    (fn [keyval code]
                       (match (tonumber code)
                         consts.KeyCode.esc (handle-esc)
                         consts.KeyCode.enter (do (run (input))
                                                true)
                         consts.KeyCode.down (do (inc-selected-index)
                                               true)
                         consts.KeyCode.up (do (dec-selected-index)
                                             true)))})
        list (list-view
               {:data cmds
                :render (fn [cmd]
                          (box 
                            {:spacing 0
                             :orientation consts.Orientation.Horizontal
                             :class (mapn [cmd selected-index] 
                                          (fn [[cmd selected]]
                                            (.. "cmd-item "
                                                (if (= cmd._data_index
                                                       selected)
                                                  "selected "
                                                  ""))))}
                            (box 
                              {:size_request (map cmd 
                                                            #(if (not= nil $1.image)
                                                               [(dpi 36) (dpi 36)]
                                                               [0 0])) 
                               :class "image"
                               :vexpand false :hexpand false
                               :valign consts.Align.Center
                               :halign consts.Align.Start}
                              (picture {:texture (map cmd #$1.image)
                                        :vexpand false
                                        :hexpand false
                                        :content_fit consts.ContentFit.Cover}))
                            (box 
                              {:spacing 0
                               :class "labels"
                               :valign consts.Align.Center}
                              (label
                                {:markup (map cmd #$1.label)
                                 :class :cmd-label
                                 :hexpand true
                                 ;:wrap true
                                 :xalign 0})
                              (let [desc (mapn [cmd input]
                                               (fn [[cmd input]]
                                                 (if cmd.real-time
                                                   (let [[_ args] (split-input input)]
                                                    (catch "" ""
                                                           (or (cmd.real-time args)
                                                               "(No description)")))
                                                   (or cmd.description "(No description)"))))]
                                (label
                                  {:label desc
                                   :class "cmd-desc"
                                   ; :wrap true
                                   ; :wrap_mode consts.WrapMode.Char
                                   :xalign 0})))))})
                                    
        on-built (use-built)
        win
        (window
          {
           : visible
           :class win-css
           :skip_taskbar_hint true
           :role :cmd-palette}
           ;:connect_focus_out_event close}
          (box
            {:orientation consts.Orientation.VERTICAL}
            cmd_input
            (scrolled-window
              {:vexpand true}
               ;:class (css [:min-height :400px])}
              list)
            (box
              {:class :tips
               :orientation consts.Orientation.Horizontal}
              (label {:hexpand true})
              (label {:label selected-index})
              (label {:label "󰜷 Ctrl+K "})
              (label {:label "󰜮 Ctrl+J "})
              (label {:label (map cmds #(.. "󰘳 " (length $1)))}))))]
    ; sync input to textbox
    (effect [input]
            (when (on-built)
              (let [entry (cmd_input)
                    text (entry:text)]
                (when (not= text (input))
                  (entry:set_text (input))))))
    ; set selected to the fist, when input changed
    (effect [input]
            (selected-index 1))
    (effect [selected-index]
      (when (on-built)
        (let [index (- (selected-index) 1)
              list (list)]
          (list:scroll_to index 2))))
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
                           (print :close)
                           (win:close)))
            (set win (run (pallet-node
                              {: visible
                               : close
                               : mgr})))
            (set running {: close})
            (visible true))))}

