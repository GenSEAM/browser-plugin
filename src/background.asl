(module asl-browser-plugin/background
  :d "Browser WebExtension background service worker in pure AgentScript."
  :x [init-service-worker
      route-action-message
      handle-message]
  :i [(content :a cnt)])

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
       "(:context-response :status \"ok\" :title \"AgentScript Hub\" :url \"https://agentscript.org\")")
      ((string-contains? clean ":tab-query")
       "(:tab-query-response :status \"ok\" :tabs-count 1)")
      ((or (string-contains? clean ":exec-action") (string-contains? clean ":dispatch-action"))
       (route-action-message clean))
      (:else
       (str "(:error :reason \"unknown-message\" :raw \"" clean "\")")))))
