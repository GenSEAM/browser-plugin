(module asl-browser-plugin/content
  :d "In-tab DOM extraction and perception content script in pure AgentScript."
  :x [PageContext
      make-page-context
      format-page-context
      extract-page-context
      is-valid-action-type?
      is-valid-selector?
      dispatch-action]
  :i [])

(dfs PageContext
  (:f url Str "Active web page URL")
  (:f title Str "Web page document title")
  (:f ax-nodes (List Str) "Compact accessibility tree node descriptors")
  (:f is-secure Bool "Indicates secure transport protocol"))

(df make-page-context [(url Str) (title Str) (ax-nodes (List Str)) (is-secure Bool)] -> PageContext
  :d "Constructs typed PageContext"
  (PageContext
    :url url
    :title title
    :ax-nodes ax-nodes
    :is-secure is-secure))

(df format-page-context [(ctx PageContext)] -> Str
  :d "Serializes PageContext into compact ASN accessibility frame"
  (str "(:ax-tree :url \"" (.-url ctx) "\" :title \"" (.-title ctx) "\" :secure " (if (.-is-secure ctx) "true" "false") " :nodes [" (string-join (.-ax-nodes ctx) " ") "])"))

(df is-valid-action-type? [(action-type Str)] -> Bool
  :d "Validates whether action type is one of click, fill, hover, key, scroll"
  (let [(act (string-lower (string-trim action-type)))]
    (or (= act "click")
        (or (= act ":click")
            (or (= act "fill")
                (or (= act ":fill")
                    (or (= act "hover")
                        (or (= act ":hover")
                            (or (= act "key")
                                (or (= act ":key")
                                    (or (= act "scroll")
                                        (= act ":scroll"))))))))))))

(df is-valid-selector? [(selector Str)] -> Bool
  :d "Validates selector non-emptiness and basic DOM query integrity"
  (let [(clean (string-trim selector))]
    (and (> (string-length clean) 0)
         (or (string-starts-with? clean "#")
             (or (string-starts-with? clean ".")
                 (or (string-starts-with? clean "[")
                     (or (string-starts-with? clean "//")
                         (or (= clean "body")
                             (or (= clean "window")
                                 (or (= clean "document")
                                     (or (string-starts-with? clean "button")
                                         (or (string-starts-with? clean "input")
                                             (or (string-starts-with? clean "a")
                                                 (or (string-starts-with? clean "div")
                                                     (string-starts-with? clean "span")))))))))))))))

(df extract-page-context [(url Str) (title Str) (dom-tree Str)] -> Str
  :d "Extracts compact accessibility frame from page metadata and dom-tree"
  (let [(is-secure (string-starts-with? url "https://"))
        (node-str (if (string-empty? (string-trim dom-tree))
                      "(:node :role \"root\" :name \"empty\")"
                      (str "(:node :role \"document\" :raw \"" dom-tree "\")")))]
    (str "(:ax-tree :url \"" url "\" :title \"" title "\" :secure " (if is-secure "true" "false") " :nodes [" node-str "])")))

(df dispatch-action [(action-type Str) (selector Str)] -> Bool
  :d "Validates and executes synthetic browser control action"
  (and (is-valid-action-type? action-type)
       (is-valid-selector? selector)))
