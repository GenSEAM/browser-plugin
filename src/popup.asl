(module browser-plugin/popup
  :d "Pure AgentScript VDOM specification for browser extension popup interface."
  :x [render-popup view-model])

(df view-model [] -> (Map Str Str)
  :d "Constructs the reactive state model for browser extension popup."
  (let [(m0 (map-empty))
        (m1 (map-set m0 "title" "ASL Agent Plugin"))
        (m2 (map-set m1 "status" "WASI Sandbox"))
        (m3 (map-set m2 "prompt" "Extract DOM & execute agent tools in browser memory:"))
        (m4 (map-set m3 "output" "Ready. Click a button to execute."))]
    m4))

(df render-popup [(vm (Map Str Str))] -> Str
  :d "Renders pure HTML from AgentScript S-expression VDOM representation."
  (let [(title (option-or (map-get vm "title") "ASL Agent Plugin"))
        (status (option-or (map-get vm "status") "WASI Sandbox"))
        (prompt (option-or (map-get vm "prompt") "Ready"))
        (out (option-or (map-get vm "output") "Ready"))]
    (str "<!DOCTYPE html>\n<html lang=\"en\">\n<head>\n  <meta charset=\"UTF-8\" />\n"
         "  <title>" title "</title>\n"
         "  <link rel=\"stylesheet\" href=\"popup.css\" />\n"
         "</head>\n<body>\n"
         "  <div class=\"header\"><strong>" title "</strong><span class=\"badge\">" status "</span></div>\n"
         "  <p>" prompt "</p>\n"
         "  <button id=\"btn-extract\">Extract DOM to S-Expression</button>\n"
         "  <button id=\"btn-eval\">Run In-Memory Wasm Benchmark</button>\n"
         "  <div id=\"output\" class=\"output\">" out "</div>\n"
         "  <script src=\"../dist/popup.js\"></script>\n"
         "</body>\n</html>")))
