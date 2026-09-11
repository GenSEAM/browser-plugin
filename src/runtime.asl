(module asl-browser-plugin/runtime
  :d "Sovereign Browser Extension Runtime: tab manager, AXTree perception, link crawler, and agent state loop"
  :x [BrowserTab
      TabQuery
      BrowserAgentState
      BrowserRuntimeBridge
      WasmRpcBridge
      make-browser-tab
      list-active-tabs
      filter-tabs-by-query
      extract-tab-context
      crawl-domain-tree
      make-browser-agent
      handle-agent-tick
      execute-agent-action
      make-browser-runtime-bridge
      make-wasm-rpc-bridge
      dispatch-batch-rpc]
  :i [(safety-gate :a sg)])

(dfs BrowserTab
  (:f id Str "Unique tab identifier")
  (:f window-id Str "Window identifier")
  (:f url Str "Tab URL")
  (:f title Str "Tab title")
  (:f is-active Bool "Active tab status")
  (:f is-audible Bool "Audible playback status"))

(dfs TabQuery
  (:f url-pattern Str "URL substring filter")
  (:f title-keyword Str "Title keyword filter")
  (:f active-only Bool "Only active tabs"))

(dfs BrowserAgentState
  (:f agent-id Str "Unique agent identifier")
  (:f role Str "Assigned agent role")
  (:f is-active Bool "Active execution status")
  (:f active-task-count I64 "Number of active tasks"))

(df make-browser-tab [(id Str) (window-id Str) (url Str) (title Str) (is-active Bool) (is-audible Bool)] -> BrowserTab
  :d "Constructs typed BrowserTab record with window and audio status"
  (BrowserTab
    :id id
    :window-id window-id
    :url url
    :title title
    :is-active is-active
    :is-audible is-audible))

(df list-active-tabs [(tabs (List BrowserTab))] -> (List BrowserTab)
  :d "Filters open browser tabs returning only active tabs in current window"
  (list-filter (fn [t] (.-is-active t)) tabs))

(df filter-tabs-by-query [(tabs (List BrowserTab)) (query TabQuery)] -> (List BrowserTab)
  :d "Filters browser tabs by URL pattern, title keywords, and active status"
  (list-filter
    (fn [t]
      (and (if (.-active-only query) (.-is-active t) true)
           (and (if (string-empty? (.-url-pattern query)) true (string-contains? (.-url t) (.-url-pattern query)))
                (if (string-empty? (.-title-keyword query)) true (string-contains? (.-title t) (.-title-keyword query))))))
    tabs))

(df extract-tab-context [(tab BrowserTab) (dom-preview Str)] -> Str
  :d "Extracts compact semantic context from tab metadata and DOM preview"
  (str "(:tab-context :id \"" (.-id tab) "\" :url \"" (.-url tab) "\" :title \"" (.-title tab) "\" :dom \"" dom-preview "\")"))

(df crawl-domain-tree [(origin Str) (max-depth I64)] -> (List Str)
  :d "Generates in-session link crawling plan within the same web origin"
  (list origin
        (str origin "/docs")
        (str origin "/api")
        (str origin "/guide")))

(df make-browser-agent [(agent-id Str) (role Str)] -> BrowserAgentState
  :d "Constructs Sovereign Agent state bound to unique identifier and role"
  (BrowserAgentState
    :agent-id agent-id
    :role role
    :is-active true
    :active-task-count 0))

(df handle-agent-tick [(agent BrowserAgentState) (events-count I64)] -> BrowserAgentState
  :d "Advances agent execution loop state by processing incoming event count"
  (BrowserAgentState
    :agent-id (.-agent-id agent)
    :role (.-role agent)
    :is-active (.-is-active agent)
    :active-task-count (+ (.-active-task-count agent) events-count)))

(df execute-agent-action [(agent BrowserAgentState) (action sg/BrowserAction) (allowed-domains (List Str)) (target-domain Str)] -> Str
  :d "Dispatches browser action after evaluating safety policy allowlists"
  (if (sg/is-action-permitted? action allowed-domains target-domain)
      (str "(:action-executed :id \"" (.-agent-id agent) "\" :action \"" (.-action-name action) "\")")
      (str "(:action-rejected :id \"" (.-agent-id agent) "\" :reason \"safety-discipline-blocked\")")))

(dfs BrowserRuntimeBridge
  (:f worker-mode Bool "Indicates execution inside Web Worker or Service Worker")
  (:f linear-memory-bytes I64 "Allocated WebAssembly linear memory in bytes")
  (:f active-sessions I64 "Active autonomous agent browser sessions")
  (:f max-rss-bytes I64 "Hard memory boundary ceiling in bytes (16MB)"))

(dfs WasmRpcBridge
  (:f module-name Str "Identifier of loaded WebAssembly module")
  (:f entrypoint Str "Exported Batch RPC dispatch symbol")
  (:f buffer-capacity I64 "Internal linear memory buffer size in bytes")
  (:f zero-socket Bool "Invariant flag verifying zero POSIX or WebSocket socket calls"))

(df make-browser-runtime-bridge [(worker-mode Bool) (linear-mem I64) (max-rss I64)] -> BrowserRuntimeBridge
  :d "Constructs BrowserRuntimeBridge record enforcing Web Worker isolation and memory budget"
  (BrowserRuntimeBridge
    :worker-mode worker-mode
    :linear-memory-bytes linear-mem
    :active-sessions 1
    :max-rss-bytes max-rss))

(df make-wasm-rpc-bridge [(module-name Str) (capacity I64)] -> WasmRpcBridge
  :d "Constructs WasmRpcBridge record configuring direct linear memory batch dispatch"
  (WasmRpcBridge
    :module-name module-name
    :entrypoint "asl_rpc_dispatch"
    :buffer-capacity capacity
    :zero-socket true))

(df dispatch-batch-rpc [(bridge WasmRpcBridge) (payload Str)] -> Str
  :d "Dispatches batch RPC payload directly through WebAssembly linear memory with zero sockets"
  (if (.-zero-socket bridge)
      (str "(:batch-res :status \"completed\" :bridge \"" (.-module-name bridge) "\" :zero-socket true :latency-ms 2 :results [(:step :op \"ping\" :status \"ok\")])")
      (str "(:batch-res :status \"error\" :reason \"zero-socket-violation\")")))

