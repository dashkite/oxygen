import assert from "@dashkite/assert"
import * as a from "@dashkite/amen"
import Router from "@dashkite/oxygen"

# assert = chai.assert
router = Router.create()

Router.add router, "/hello/{name}",
  name: "greeting"
  ({bindings}) ->
    window.greeting = "hello, #{bindings.name}"

do ->

  window.__test = await a.test "Oxygen", [

    a.test "import", ->
      router.browse url: "/hello/alice"
      assert.equal window.greeting, "hello, alice"
  ]
