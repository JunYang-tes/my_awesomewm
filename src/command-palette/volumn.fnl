(local process (require :utils.process))
(local inspect (require :inspect))
(local list (require :utils.list))
(local stringx (require :utils.string))

(fn parse-content [card]
  (-> "amixer -c %s"
      (string.format card)
      process.read-popen
      (list.split-by 
        (fn [item]
          (stringx.starts-with item :Simple)))
      (list.map
        (fn [[control & content]]
          (let [control (stringx.replace control "Simple mixer control " "")
                type (if (list.some content #(stringx.includes $1 "Playback channels"))
                         :playback
                         :capture)]
            {: control
             : type})))))
(fn get-card-count []
  (var i 0)
  (fn test []
    (let [r
            (-> "amixer -c %s"
                (string.format i)
                process.read-popen
                table.concat)]
      (if (> (length r) 0)
          (do
            (set i (+ i 1))
            (test)))))
  (test)
  i)

(local set-volumn
       {:label :set-volumn
        :exec (fn []
                (let [count (get-card-count)
                      sub-cmds []]
                  (for [i 0 count]
                    (each [_ item (ipairs (parse-content i))]
                      (table.insert
                        sub-cmds
                        {:label item.control
                         :real-time (fn [input]
                                      (if (stringx.is-empty input)
                                          "e.g 10%+ 10%- 10"
                                          ""))
                         :exec (fn [input]
                                 (-> "amixer -c %s set %s %s "
                                   (string.format i item.control input)
                                   (process.read-popen))
                                 :keep-open)})))
                  sub-cmds))})

[set-volumn]
