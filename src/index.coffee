import {curry, tee} from "panda-garden"
import {Router} from "panda-router"
import TemplateParser from "url-template"

class PageRouter

  constructor: ({@router = new Router, @handlers = {}} = {}) ->

  @create: -> new PageRouter arguments...

  @add: curry tee ({router, handlers}, template, data, handler) ->
    router.add {template, data}
    handlers[data.name] = handler

  @match: curry ({router}, path) -> router.match path

  # TODO this seems like it belongs somewhere else
  @relative: (url) ->
    if /^[^\/]/.test url
      {pathname, search} = new URL url
      pathname + search
    else
      url

  @dispatch: curry ($, {url, name, parameters}) ->
    {router, handlers} = $
    url ?= PageRouter.link {name, parameters}
    path = PageRouter.relative url
    try
      {data, bindings} = PageRouter.match $, path
    catch error
      throw @error "dispatch: failed to match '#{url}'", error
    try
      handlers[data.name] {path, data, bindings}
    catch error
      throw PageRouter.error "dispatch: no handler defined for '#{data.name}'"

  @link: curry ({router}, {name, parameters}) ->
    console.log {router}
    for route in router.routes
      if route.data.name == name
        return TemplateParser
          .parse route.template
          .expand parameters ? {}

    throw PageRouter.error "link: no page matching '#{name}'"

  @push: curry ($, {url, name, parameters, state}) ->
    url ?= PageRouter.link $, {name, parameters}
    window.history.pushState state, "", url

  @replace: curry ($, {url, name, parameters, state}) ->
    url ?= PageRouter.link $, {name, parameters}
    window.history.replaceState state, "", url

  @browse: curry ($, {url, name, parameters, state}) ->
    url ?= PageRouter.link $, {name, parameters}
    # pushState will throw if undefined
    try
      PageRouter.push $, {url, state}
      PageRouter.dispatch $, {url}
    catch error
      throw PageRouter.error "browse: unable to dispatch '#{url}'"
      # For non-local URLs, open the link in a new tab.
      window.open url

  @error: (message, _error) ->
    error = new Error "oxygen: #{message}"
    if _error?
      error.originalError = _error
    error

{add, dispatch, link, push, replace, browse} = PageRouter

# add shortcuts
for name, fn of {add, dispatch, link, push, replace, browse}
  do (name, fn) -> PageRouter::[name] = -> fn @, arguments...

# allow direct references
export {dispatch, link, push, replace, browse}
export default PageRouter
