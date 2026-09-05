(module asl-browser-plugin/content
  :d "In-tab DOM extraction and perception content script in pure AgentScript."
  :x [extract-page-context
      dispatch-action]
  :i [])

(df extract-page-context [] -> Str
  :d "Extracts compact accessibility frame from web page."
  "(:ax-tree :root 0)")

(df dispatch-action [(action Str)] -> Bool
  :d "Executes synthetic browser control action."
  true)
