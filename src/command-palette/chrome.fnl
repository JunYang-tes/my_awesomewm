(local {: server } (require :utils.ws))
(local stringx (require :utils.string))
(local list (require :utils.list))
(local json (require :cjson))

(local tabs
  {:label "Chrome tabs"
   :exec (fn []
           (let [(ok conn) (pcall #(server:connection :/chrome))]
             (if ok
               (let [resp (conn:send (json.encode
                                       {:method :getTabs}) 500)
                     {: result
                      : type } (json.decode resp)]
                 (match type
                   :error [{:label result}]
                   :ok (-> result
                           (list.map #{:label $1.title
                                       :exec (fn []
                                               (conn:send
                                                 (json.encode
                                                   {:method :activeTab
                                                    :args [$1.windowId $1.id]})
                                                 200))}))))
               [{:label "Chrome extension is not running"}])))})
(local bookmarks
  {:label "Chrome bookmarks"
   :exec (fn []
           (let [(ok conn) (pcall #(server:connection :/chrome))]
             (if ok
               (let [resp (conn:send (json.encode
                                       {:method :getBookmarks
                                        :args [200]}) 500)
                     {: result
                      : type } (json.decode resp)]
                 (match type
                   :error [{:label result}]
                   :ok (-> result
                           (list.map #{:label $1.title
                                       :exec (fn []
                                               (conn:send
                                                 (json.encode
                                                   {:method :newTab
                                                    :args [{:url $1.url}]})
                                                 200))}))))
               [{:label "Chrome extension is not running"}])))})
(local history
  {:label "Chrome history"
   :exec (fn [text]
           (let [(ok conn) (pcall #(server:connection :/chrome))]
             (if ok
               (let [resp (conn:send (json.encode
                                       {:method :getHistory
                                        :args [{: text}]}) 500)
                     {: result
                      : type } (json.decode resp)]
                 (match type
                   :error [{:label result}]
                   :ok (-> result
                           (list.map #{:label $1.title
                                       :exec (fn []
                                               (conn:send
                                                 (json.encode
                                                   {:method :newTab
                                                    :args [{:url $1.url}]})
                                                 200))}))))
               [{:label "Chrome extension is not running"}])))})

{: tabs
 : history
 : bookmarks}
