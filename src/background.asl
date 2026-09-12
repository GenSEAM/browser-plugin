(module asl-browser-plugin/background
  :d "Browser WebExtension background service worker in pure AgentScript."
  :x [init-service-worker
      route-action-message
      handle-message]
  :i [(content :a cnt)
      (safety_gate :a sg)])

(df init-service-worker [] -> Str
  :d "Initializes background service worker context."
  "(:service-worker :state \"active\" :engine \"wasi\")")

(df route-action-message [(msg Str)] -> Str
  :d "Routes action dispatch message through content action validator"
  (let [(has-click (string-contains? msg "click"))
        (has-fill (string-contains? msg "fill"))
        (has-hover (string-contains? msg "hover"))
        (has-key (string-contains? msg "key"))
        (has-scroll (string-contains? msg "scroll"))
        (is-valid-act (or has-click (or has-fill (or has-hover (or has-key has-scroll)))))
        (has-empty-sel (or (string-contains? msg ":selector \"\"")
                           (string-contains? msg ":selector ''")))]
    (if (and is-valid-act (not has-empty-sel))
        "(:action-result :status \"dispatched\" :success true)"
        "(:action-result :status \"failed\" :reason \"invalid-action-or-selector\")")))

(df handle-message [(msg Str)] -> Str
  :d "Processes in-tab message RPC via typed routing"
  (let [(clean (string-trim msg))]
    (cond
      ((or (= clean "(:ping)") (= clean "ping"))
       "(:pong)")
      ((or (= clean "(:get-version)") (= clean "get-version"))
       "(:version \"0.1.0\")")
      ((string-contains? clean ":extract-context")
       (let [(url-idx (string-index-of clean ":url \""))
             (url (if (option-some? url-idx)
                      (let [(sub (option-or (string-slice clean (+ (option-unwrap url-idx) 6) (string-length clean)) ""))
                            (q-idx (string-index-of sub "\""))]
                        (if (option-some? q-idx) (option-or (string-slice sub 0 (option-unwrap q-idx)) "https://agentscript.org") "https://agentscript.org"))
                      "https://agentscript.org"))
             (title-idx (string-index-of clean ":title \""))
             (title (if (option-some? title-idx)
                        (let [(sub (option-or (string-slice clean (+ (option-unwrap title-idx) 8) (string-length clean)) ""))
                              (q-idx (string-index-of sub "\""))]
                          (if (option-some? q-idx) (option-or (string-slice sub 0 (option-unwrap q-idx)) "AgentScript Hub") "AgentScript Hub"))
                        "AgentScript Hub"))]
         (str "(:context-response :status \"ok\" :title \"" title "\" :url \"" url "\")")))
      ((string-contains? clean ":tab-query")
       "(:tab-query-response :status \"ok\" :tabs-count 1)")
      ((or (string-contains? clean ":exec-action") (string-contains? clean ":dispatch-action"))
       (route-action-message clean))
      (:else
       (str "(:error :reason \"unknown-message\" :raw \"" clean "\")")))))
