import {curry, tee} from "@pandastrike/garden"
import {Router} from "@pandastrike/router"
import TemplateParser from "url-template"
import {error, relative} from "./helpers"

class PageRouter

  @create: (ax...) -> new PageRouter ax...
  @add: curry (router, template, data, handler) ->
    router.add template, data, handler
  @dispatch: curry (router, description, context) ->
    router.dispatch description, context
  @link: curry (router, description) -> router.link description
  @push: curry (router, description) -> router.push description
  @replace: curry (router, description) -> router.replace description
  @browse: curry (router, description) -> router.browse description

  constructor: ({@router = new Router, @handlers = {}} = {}) ->

  add: (template, data, handler) ->
    @router.add {template, data}
    @handlers[data.name] = handler

  match: (path) -> @router.match path

  dispatch: ({url, name, parameters}, context) ->
    url ?= @link {name, parameters}
    path = relative url
    try
      console.log "oxygen: matching path #{path}"
      result = @match path
      console.log "oxygen: match result", result
      {data, bindings} = result
      @handlers[data.name] {path, data, bindings}, context
    catch _error
      console.warn _error
      throw error "dispatch: failed with [#{url}]"

  # TODO remove parameters that are empty strings
  link: ({name, parameters}) ->
    for route in @router.routes
      if route.data.name == name
        return TemplateParser
          .parse route.template
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
