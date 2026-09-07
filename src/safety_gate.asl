(module asl-browser-plugin/safety-gate
  :d "Browser command safety gate: 3-tier action validation and role negotiation"
  :x [BrowserAction classify-action-tier validate-browser-action is-action-permitted? make-browser-action]
  :i [(tool_plane :a tp)])

(dfs BrowserAction
  (:f action-name Str "Action identifier")
  (:f tier ToolSafety "Safety tier")
  (:f target-tab Str "Target tab id")
  (:f payload Str "Action payload")
  (:f is-confirmed Bool "True if explicit user confirmation received in popup"))

(df classify-action-tier [(action-name Str)] -> ToolSafety
  :d "Classifies command into safe, guarded, or dangerous tier"
  (let [(act (string-lower action-name))]
    (cond
      ((or (= act "list-tabs")
           (or (= act "get-dom")
               (or (= act "search")
                   (or (= act "extract-text")
                       (= act "get-tab-info")))))
       (tp/safety-safe))
      ((or (= act "open-tab")
           (or (= act "scroll")
               (or (= act "switch-tab")
                   (= act "click-link"))))
       (tp/safety-guarded))
      (:else
       (tp/safety-dangerous)))))

(df make-browser-action [(action-name Str) (target-tab Str) (payload Str) (is-confirmed Bool)] -> BrowserAction
  :d "Constructs typed BrowserAction record bound to safety tier and target tab"
  (BrowserAction
    :action-name action-name
    :tier (classify-action-tier action-name)
    :target-tab target-tab
    :payload payload
    :is-confirmed is-confirmed))

(df is-action-permitted? [(action BrowserAction) (allowed-domains (List Str)) (target-domain Str)] -> Bool
  :d "Validates action execution under safety discipline and role permissions"
  (mt (.-tier action)
    ((safety-safe) true)
    ((safety-guarded)
     (if (list-empty? allowed-domains)
         true
         (list-contains? allowed-domains target-domain)))
    ((safety-dangerous)
     (.-is-confirmed action))))

(df validate-browser-action [(action-name Str) (is-confirmed Bool) (allowed-domains (List Str)) (target-domain Str)] -> Bool
  :d "Validates whether action meets safety constraints and allowed domains"
  (let [(act (make-browser-action action-name "tab-1" "" is-confirmed))]
    (is-action-permitted? act allowed-domains target-domain)))
