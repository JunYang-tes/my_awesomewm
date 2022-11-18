(local naughty (require :naughty))
(local cfg (require :utils.cfg))
(local {: find } (require :utils.list))
(local {: includes } (require :utils.string))
(local {: assign } (require :utils.table))
(local inspect (require :inspect))
(local conf (cfg.load-cfg :notification { :default "show"
                                          :rules []})) 

(fn modifiy-notification [{: title : text}] 
  (local r (find conf.rules (fn [r] 
                              (includes 
                                (if (= r.target :title) 
                                    title 
                                    text) 
                                r.pattern)))) 
  (if (and r 
           (= r.action "hide")) 
      {: title 
       :text "(New Message)"} 
      (= conf.default :show) {: title : text} {: title :text "(New Message)"}))

(local notify naughty.notify)
(set naughty.notify 
  (fn [param]
    (print "New notification" param.title param.text) 
    (local r (modifiy-notification {:title param.title :text param.text})) 
    (if r 
        (notify (assign param r))))) 
