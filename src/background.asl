(module asl-browser-plugin/background
  :d "Browser WebExtension background service worker in pure AgentScript."
  :x [init-service-worker
      handle-message]
  :i [])

(df init-service-worker [] -> Str
  :d "Initializes background service worker context."
  "Service worker initialized.")

(df handle-message [(msg Str)] -> Str
  :d "Processes in-tab message RPC."
  (str "ACK:" msg))
