import assert from "assert"
import {print, test, success} from "amen"
import Router, {dispatch} from "../src"

do ->

  print await test "oxygen", [

    test "dispatch", ->

      router = Router.create()

      name = undefined
      router.add "/hello/{name}",
        name: "greeting"
        ({bindings}) -> name = bindings.name

      router.dispatch url: "/hello/dan"

      assert.equal "dan", name
  ]
