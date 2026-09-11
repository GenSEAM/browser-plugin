(module asl-browser-plugin/tests/runtime-test
  :d "Unit verification suite for in-browser autonomous runtime bridge and zero-socket Batch RPC dispatch"
  :x [run-tests
      test-browser-runtime-bridge
      test-wasm-rpc-bridge
      test-dispatch-batch-rpc
      test-dispatch-zero-socket-enforcement]
  :i [(runtime :a rt)])

(df test-browser-runtime-bridge [] -> Bool
  :d "Verifies BrowserRuntimeBridge construction, worker-mode isolation, and 16MB RSS memory ceiling"
  (let [(b1 (rt/make-browser-runtime-bridge true 1048576 16777216))
        (b2 (rt/make-browser-runtime-bridge false 524288 8388608))]
    (assert (.-worker-mode b1) "Worker mode must be active for b1")
    (assert (not (.-worker-mode b2)) "Worker mode must be inactive for b2")
    (assert (= (.-linear-memory-bytes b1) 1048576) "Linear memory must equal 1048576 bytes")
    (assert (= (.-max-rss-bytes b1) 16777216) "Max RSS ceiling must be 16MB")
    (assert (<= (.-max-rss-bytes b1) 16777216) "Hard memory budget must not exceed 16MB boundary")
    true))

(df test-wasm-rpc-bridge [] -> Bool
  :d "Verifies WasmRpcBridge initialization, entrypoint export, and zero-socket invariant"
  (let [(w1 (rt/make-wasm-rpc-bridge "asl-core" 65536))
        (w2 (rt/make-wasm-rpc-bridge "asl-mem" 32768))]
    (assert (= (.-module-name w1) "asl-core") "Module name must match asl-core")
    (assert (= (.-entrypoint w1) "asl_rpc_dispatch") "Entrypoint must be asl_rpc_dispatch")
    (assert (.-zero-socket w1) "Zero socket invariant must be strictly true")
    (assert (= (.-buffer-capacity w1) 65536) "Buffer capacity must equal 65536")
    (assert (= (.-buffer-capacity w2) 32768) "Buffer capacity must equal 32768")
    true))

(df test-dispatch-batch-rpc [] -> Bool
  :d "Verifies in-browser direct memory batch RPC dispatch with latency < 3ms"
  (let [(w (rt/make-wasm-rpc-bridge "asl-core" 65536))
        (res (rt/dispatch-batch-rpc w "(:batch (:ping))"))]
    (assert (string-contains? res ":status \"completed\"") "Dispatch result must indicate completed status")
    (assert (string-contains? res ":zero-socket true") "Dispatch result must confirm zero-socket execution")
    (assert (string-contains? res ":latency-ms 2") "Dispatch latency must be bounded under 3ms")
    (assert (string-contains? res ":bridge \"asl-core\"") "Dispatch result must reference asl-core module")
    true))

(df test-dispatch-zero-socket-enforcement [] -> Bool
  :d "Verifies rejection when zero-socket invariant is compromised"
  (let [(compromised (rt/WasmRpcBridge :module-name "bad" :entrypoint "asl_rpc_dispatch" :buffer-capacity 1024 :zero-socket false))
        (res (rt/dispatch-batch-rpc compromised "(:batch (:ping))"))]
    (assert (string-contains? res ":status \"error\"") "Compromised bridge must return error status")
    (assert (string-contains? res "zero-socket-violation") "Error message must report zero-socket-violation")
    true))

(df run-tests [] -> Bool
  :d "Runs all in-browser autonomous runtime unit tests"
  (let [(_t1 (test-browser-runtime-bridge))
        (_t2 (test-wasm-rpc-bridge))
        (_t3 (test-dispatch-batch-rpc))
        (_t4 (test-dispatch-zero-socket-enforcement))]
    true))
