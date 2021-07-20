import { curry, tee, pipe, flow } from "@dashkite/joy/function"
import { events } from "@dashkite/joy/iterable"
import { Router } from "@pandastrike/router"
import TemplateParser from "es6-url-template"
import { navigate } from "@dashkite/navigate"
import { error, relative } from "./helpers"

class PageRouter

  @create: (ax...) -> new PageRouter ax...
  @install: (router) -> router.install()
  @add: curry (router, template, data, handler) ->
    router.add template, data, handler
  @dispatch: curry (router, description, context) ->
    router.dispatch description, context
  @link: curry (router, description) -> router.link description
  @push: curry (router, description) -> router.push description
  @replace: curry (router, description) -> router.replace description
  @browse: curry (router, description) -> router.browse description

  constructor: ({@router, @handlers, @options} = {}) ->
    @router ?= new Router
    @handlers ?= {}

  install: ->

    do =>
      for await url from navigate window
        @browse { url }

    do =>
      for await event from events "popstate", window
        @dispatch
          url: window.location.href
          state: event.state

  add: (template, data, handler) ->
    @router.add {template, data}
    @handlers[data.name] = handler

  match: (path) -> @router.match path

  dispatch: ({url, name, parameters}, context) ->
    url ?= @link {name, parameters}
    path = relative url
    if (result = @match path)?
      {data, bindings} = result
      try
        @handlers[data.name] {path, data, bindings}, context
      catch _error
        console.warn _error
        throw error "handler failed for [#{url}]"
    else
      throw error "dispatch: no matching route for [#{url}]"

  # TODO remove parameters that are empty strings
  link: ({name, parameters}) ->
    for route in @router.routes
      if route.data.name == name
        return (new TemplateParser route.template)
          .expand parameters ? {}

  push: ({url, name, parameters, state}) ->
    url ?= @link {name, parameters}
    window.history.pushState state, "", url

  replace: ({url, name, parameters, state}) ->
    url ?= @link {name, parameters}
    window.history.replaceState state, "", url

  browse: ({url, name, parameters, state}) ->
    url ?= @link {name, parameters}
    # For non-local URLs, open the link in a new tab.
    try
      @push {url, state}
    catch _error
      window.open url
    @dispatch {url}

{add, dispatch, link, push, replace, browse} = PageRouter

export {dispatch, link, push, replace, browse}
export default PageRouter
