(module asl-browser-plugin/dom-compiler
  :d "In-page DOM interaction compiler: synthesizes atomic JS/WASM probes from ASL expressions"
  :x [compile-probe-js compile-table-extractor compile-text-selector]
  :i [])

(df compile-probe-js [(target-selector Str) (attribute Str)] -> Str
  :d "Compiles DOM query into an atomic self-executing JS probe"
  (str "(() => {\nconst el = document.querySelector('" target-selector "')\nreturn el ? el.getAttribute('" attribute "') : null\n})()"))

(df compile-table-extractor [(table-selector Str)] -> Str
  :d "Compiles structured table extraction probe returning JSON matrix"
  (str "(() => {\nconst rows = Array.from(document.querySelectorAll('" table-selector " tr'))\nreturn JSON.stringify(rows.map(r => Array.from(r.children).map(c => c.textContent.trim())))\n})()"))

(df compile-text-selector [(selector Str)] -> Str
  :d "Compiles text content extraction probe with whitespace normalization"
  (str "(() => {\nconst el = document.querySelector('" selector "')\nreturn el ? el.innerText.trim() : ''\n})()"))
