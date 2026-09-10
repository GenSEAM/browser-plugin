(module asl-browser-plugin/plugin
  :d "Main package entrypoint for Aslany Browser Plugin & AudioWorklet Voice Operator"
  :x [start-plugin get-plugin-version get-aslany-brand]
  :i [(runtime :a rt)
      (safety-gate :a sg)
      (local-slm :a slm)
      (mesh-client :a mc)
      (dom-compiler :a dc)])

(df get-plugin-version [] -> Str
  :d "Returns active browser extension plugin semantic version string"
  "1.0.0")

(df get-aslany-brand [] -> Str
  :d "Returns canonical brand name for unified agent and plugin"
  "Aslany")

(df start-plugin [] -> Str
  :d "Entrypoint starting browser extension agent service worker"
  "Aslany Browser Plugin initialized with AudioWorklet 16kHz and CDP bridge.")
