(module asl-browser-plugin/mesh-client
  :d "Swarm Mesh peer client: remote delegation and structured frame dispatch"
  :x [MeshNodeInfo MeshCommandPacket format-node-registration format-mesh-response parse-mesh-command]
  :i [(mesh :a m)])

(dfs MeshNodeInfo
  (:f node-id Str "Unique node identifier")
  (:f role Str "Assigned mesh role")
  (:f transport Str "Transport mechanism: wasm-channel")
  (:f capabilities (List Str) "List of supported actions"))

(dfs MeshCommandPacket
  (:f from-node Str "Originating node id")
  (:f to-node Str "Target destination node id")
  (:f command-id Str "Unique command id")
  (:f action-name Str "Action name")
  (:f payload Str "Action payload"))

(df format-node-registration [(node-id Str) (role Str)] -> MeshNodeInfo
  :d "Builds Swarm Mesh peer node registration packet for browser agent"
  (MeshNodeInfo
    :node-id node-id
    :role role
    :transport "wasm-channel"
    :capabilities (list "list-tabs" "get-dom" "search-tab" "crawl-links" "extract-text")))

(df format-mesh-response [(cmd-id Str) (status Str) (data Str)] -> Str
  :d "Encodes structured ASN frame response to remote Swarm Mesh caller"
  (str "(:mesh-response :command-id \"" cmd-id "\" :status \"" status "\" :data \"" data "\")"))

(df parse-mesh-command [(from Str) (to Str) (cmd-id Str) (act Str) (payload Str)] -> MeshCommandPacket
  :d "Parses incoming remote command packet from peer Swarm Mesh nodes"
  (MeshCommandPacket
    :from-node from
    :to-node to
    :command-id cmd-id
    :action-name act
    :payload payload))
