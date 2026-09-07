(module asl-browser-plugin/local-slm
  :d "Dual-inference controller: On-device WebGPU SLM vs Gateway proxy delegation"
  :x [InferenceRoute InferenceTarget select-inference-route dispatch-local-perception evaluate-confidence]
  :i [(mesh :a m)])

(dfe InferenceTarget
  (:c on-device-webgpu [] "Local in-browser WebLLM / WebGPU execution")
  (:c remote-gateway-proxy [] "Forwarded to Agent Bus L7 Gateway proxy"))

(dfs InferenceRoute
  (:f target InferenceTarget "Selected inference target")
  (:f model-name Str "Model identifier")
  (:f estimated-latency-ms I64 "Predicted execution latency in ms")
  (:f reason Str "Routing rationale")
  (:f tier ComputeTier "Mapped mesh compute tier"))

(df select-inference-route [(task-kind Str) (has-webgpu Bool) (requires-deep-reasoning Bool)] -> InferenceRoute
  :d "Routes perception and reasoning between local SLM and remote gateway"
  (if (and has-webgpu (not requires-deep-reasoning))
      (InferenceRoute
        :target (InferenceTarget:on-device-webgpu)
        :model-name "gemma-2b-it-webgpu"
        :estimated-latency-ms 15
        :reason "Low-latency in-browser WebGPU perception"
        :tier (m/tier-1-edge-mediator))
      (InferenceRoute
        :target (InferenceTarget:remote-gateway-proxy)
        :model-name "gateway-l7-reasoning"
        :estimated-latency-ms 450
        :reason "High-reasoning task delegated to Agent Bus Gateway"
        :tier (m/tier-3-frontier-reasoning))))

(df evaluate-confidence [(confidence F64) (threshold F64)] -> Bool
  :d "Checks if local model confidence meets acceptance threshold"
  (>= confidence threshold))

(df dispatch-local-perception [(prompt Str) (context Str)] -> Str
  :d "Simulates on-device lightweight perception output format"
  (str "(:perception-result :summary \"" (option-or (string-slice prompt 0 80) prompt) "\" :tokens 45)"))
