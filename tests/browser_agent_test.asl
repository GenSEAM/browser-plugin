(module asl-browser-plugin/tests/browser-agent-test
  :d "Comprehensive test suite for In-Browser Sovereign Agent, Tab Manager, Safety Gate, and Mesh Client"
  :x [test-tab-manager
      test-safety-gate
      test-local-inference-routing
      test-mesh-client
      test-dom-compiler
      test-agent-lifecycle
      run-tests]
  :i [(runtime :a rt)
      (safety-gate :a sg)
      (local-slm :a slm)
      (mesh-client :a mc)
      (dom-compiler :a dc)
      (tool_plane :a tp)
      (plugin :a pl)])

(df test-tab-manager [] -> Bool
  :d "Verifies tab enumeration, active tab filtering, and query matching"
  (let [(t1 (rt/make-browser-tab "1" "win-1" "https://agentscript.org/docs" "ASL Documentation" true false))
        (t2 (rt/make-browser-tab "2" "win-1" "https://github.com/asl/core" "GitHub Core" false false))
        (t3 (rt/make-browser-tab "3" "win-1" "https://agentscript.org/blog" "ASL Architecture Blog" false false))
        (tabs (list t1 t2 t3))
        (active (rt/list-active-tabs tabs))
        (q (rt/TabQuery :url-pattern "agentscript.org" :title-keyword "" :active-only false))
        (matched (rt/filter-tabs-by-query tabs q))]
    (assert (= (list-length active) 1) "should have exactly 1 active tab")
    (assert (= (.-id (option-or (list-head active) t2)) "1") "active tab id must be 1")
    (assert (= (list-length matched) 2) "should match 2 agentscript tabs")
    (let [(ctx (rt/extract-tab-context t1 "<html><body><h1>ASL Docs</h1></body></html>"))]
      (assert (string-contains? ctx "ASL Documentation") "extracted context should contain title")
      (assert (string-contains? ctx "https://agentscript.org/docs") "extracted context should contain url"))
    (let [(tree (rt/crawl-domain-tree "https://example.com" 2))]
      (assert (= (list-length tree) 4) "crawl plan should have 4 URLs"))
    true))

(df test-safety-gate [] -> Bool
  :d "Verifies 3-tier action validation with ToolSafety, domain allowlists, and dangerous action blocking"
  (let [(act-safe (sg/make-browser-action "list-tabs" "1" "" false))
        (act-guarded (sg/make-browser-action "open-tab" "1" "https://agentscript.org" false))
        (act-dangerous (sg/make-browser-action "eval-js" "1" "document.cookie" false))
        (act-confirmed (sg/make-browser-action "eval-js" "1" "console.log('hi')" true))
        (allowed (list "agentscript.org" "github.com"))]
    (assert (= (.-tier act-safe) (tp/safety-safe)) "list-tabs should be ToolSafety safe")
    (assert (= (.-tier act-guarded) (tp/safety-guarded)) "open-tab should be ToolSafety guarded")
    (assert (= (.-tier act-dangerous) (tp/safety-dangerous)) "eval-js should be ToolSafety dangerous")
    (assert (= (sg/is-action-permitted? act-safe allowed "agentscript.org") true) "safe action must always be permitted")
    (assert (= (sg/is-action-permitted? act-guarded allowed "agentscript.org") true) "guarded action on allowed domain permitted")
    (assert (= (sg/is-action-permitted? act-guarded allowed "malicious.com") false) "guarded action on disallowed domain rejected")
    (assert (= (sg/is-action-permitted? act-dangerous allowed "agentscript.org") false) "unconfirmed dangerous action rejected")
    (assert (= (sg/is-action-permitted? act-confirmed allowed "agentscript.org") true) "confirmed dangerous action permitted")
    (assert (= (sg/validate-browser-action "list-tabs" false allowed "agentscript.org") true) "validate-browser-action safe should succeed")
    (assert (= (sg/validate-browser-action "eval-js" false allowed "agentscript.org") false) "validate-browser-action unconfirmed dangerous should fail")
    (assert (= (sg/validate-browser-action "eval-js" true allowed "agentscript.org") true) "validate-browser-action confirmed dangerous should succeed")
    true))

(df test-local-inference-routing [] -> Bool
  :d "Verifies dual-inference router between on-device WebGPU and remote gateway"
  (let [(route-local (slm/select-inference-route "summarize-dom" true false))
        (route-remote (slm/select-inference-route "solve-complex-puzzle" true true))
        (route-nowebgpu (slm/select-inference-route "summarize-dom" false false))]
    (assert (= (.-target route-local) (slm/InferenceTarget:on-device-webgpu)) "local route target should be webgpu")
    (assert (= (.-target route-remote) (slm/InferenceTarget:remote-gateway-proxy)) "deep reasoning should use gateway")
    (assert (= (.-target route-nowebgpu) (slm/InferenceTarget:remote-gateway-proxy)) "no webgpu should fallback to gateway")
    (assert (= (slm/evaluate-confidence 0.92 0.85) true) "0.92 confidence should pass 0.85 threshold")
    (assert (= (slm/evaluate-confidence 0.71 0.85) false) "0.71 confidence should fail 0.85 threshold")
    (let [(res (slm/dispatch-local-perception "Analyze this page" "Context"))]
      (assert (string-contains? res ":perception-result") "perception result format mismatch"))
    true))

(df test-mesh-client [] -> Bool
  :d "Verifies node registration, command packet serialization, and mesh response frames"
  (let [(node (mc/format-node-registration "browser-node-42" "browser-copilot"))
        (pkt (mc/parse-mesh-command "eddie-tui" "browser-node-42" "cmd-1" "list-tabs" ""))
        (resp (mc/format-mesh-response "cmd-1" "ok" "(:tabs-count 3)"))]
    (assert (= (.-node-id node) "browser-node-42") "node id mismatch")
    (assert (= (.-role node) "browser-copilot") "role mismatch")
    (assert (= (.-transport node) "wasm-channel") "transport mismatch")
    (assert (> (list-length (.-capabilities node)) 3) "capabilities should be non-empty")
    (assert (= (.-from-node pkt) "eddie-tui") "from node mismatch")
    (assert (= (.-action-name pkt) "list-tabs") "action name mismatch")
    (assert (string-contains? resp "(:mesh-response") "response should be ASN frame")
    (assert (string-contains? resp "cmd-1") "response should contain command id")
    true))

(df test-dom-compiler [] -> Bool
  :d "Verifies synthesis of atomic JS probes for DOM extraction"
  (let [(probe-js (dc/compile-probe-js "#main" "href"))
        (table-js (dc/compile-table-extractor "#data-table"))
        (text-js (dc/compile-text-selector ".article-body"))]
    (assert (string-contains? probe-js "document.querySelector('#main')") "probe JS selector mismatch")
    (assert (string-contains? probe-js "getAttribute('href')") "probe JS attribute mismatch")
    (assert (string-contains? table-js "document.querySelectorAll('#data-table tr')") "table extractor mismatch")
    (assert (string-contains? text-js "innerText.trim()") "text selector mismatch")
    true))

(df test-agent-lifecycle [] -> Bool
  :d "Verifies Sovereign Agent state transitions, tick processing, and plugin entrypoint"
  (let [(agent (rt/make-browser-agent "sovereign-1" "copilot"))
        (ticked (rt/handle-agent-tick agent 3))
        (act-ok (sg/make-browser-action "list-tabs" "1" "" false))
        (act-bad (sg/make-browser-action "clear-storage" "1" "" false))
        (res-ok (rt/execute-agent-action ticked act-ok (list "example.com") "example.com"))
        (res-bad (rt/execute-agent-action ticked act-bad (list "example.com") "example.com"))]
    (assert (= (.-agent-id agent) "sovereign-1") "agent id mismatch")
    (assert (= (.-is-active agent) true) "agent should be active")
    (assert (= (.-active-task-count ticked) 3) "ticked tasks count should be 3")
    (assert (string-contains? res-ok ":action-executed") "permitted action should execute")
    (assert (string-contains? res-bad ":action-rejected") "unconfirmed dangerous action should be rejected")
    (assert (= (pl/get-plugin-version) "0.1.0") "plugin version mismatch")
    (assert (string-contains? (pl/start-plugin) "initialized") "start plugin mismatch")
    true))

(df run-tests [] -> Bool
  :d "Executes all browser agent test cases"
  (and (test-tab-manager)
       (test-safety-gate)
       (test-local-inference-routing)
       (test-mesh-client)
       (test-dom-compiler)
       (test-agent-lifecycle)))
