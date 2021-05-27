import * as a from "amen"

import PageRouter from "@dashkite/oxygen"

do ->
  window.__test = await a.test "Oxygen", [

    test "import", -> PageRouter?

  ]
