import assert from "assert"
import {print, test, success} from "amen"
import Router from "../src"

do ->

  print await test "oxygen", [

    test "dispatch", ->

      name = undefined
      router = Router.create()

      Router.add router,
        "/hello/{name}",
        name: "greeting"
        ({bindings}) -> name = bindings.name

      Router.dispatch router, url: "/hello/dan"

      assert.equal "dan", name
  ]
