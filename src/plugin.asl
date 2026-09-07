(module asl-browser-plugin/plugin
  :d "Main package entrypoint for ASL Agent Browser Plugin"
  :x [start-plugin get-plugin-version]
  :i [(runtime :a rt)
      (safety-gate :a sg)
      (local-slm :a slm)
      (mesh-client :a mc)
      (dom-compiler :a dc)])

(df get-plugin-version [] -> Str
  :d "Returns active browser extension plugin semantic version string"
  "0.1.0")

(df start-plugin [] -> Str
  :d "Entrypoint starting browser extension agent service worker"
  "ASL Agent Browser Plugin initialized.")
