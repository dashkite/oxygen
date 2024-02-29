import * as Fn  from "@dashkite/joy/function"
import { generic }  from "@dashkite/joy/generic"
import * as Type  from "@dashkite/joy/type"
import * as Obj  from "@dashkite/joy/object"
import { events } from "@dashkite/joy/iterable"
import { Router } from "@dashkite/url-router"
import { navigate } from "@dashkite/navigate"
import { encode } from "@dashkite/url-codex"
import { error, relative, isSameOrigin, isCurrentLocation } from "./helpers"

# TODO fall back to 'not found' named route

# implementation is below
# declared here so we can reference it
# in the PageRouter class definition
normalize = generic name: "Oxygen.normalize"

queue = ->
  new Promise ( resolve ) ->
    queueMicrotask resolve

class PageRouter

  @create: ( ax... ) -> new PageRouter ax...

  constructor: ({ @router, @handlers, @options } = {}) ->
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

  start: ->
    loop
      before = @router.routes.length
      await do queue
      after = @router.routes.length
      if before == after
        @dispatch url: window.location.href
        break

  append: ( template, data, handler ) ->
    @router.append { template, data }
    @handlers[data.name] = handler

  prepend: ( template, data, handler ) ->
    @router.prepend { template, data }
    @handlers[data.name] = handler

  # convenience / backward compatibility
  add: ( template, data, handler ) -> 
    @prepend template, data, handler

  normalize: ( url ) -> normalize @, url

  match: ( path ) -> @router.match path

  dispatch: ({ url, path, name, parameters }, context) ->
    path ?= do =>
      url ?= @link { name, parameters }
      url = @normalize url
      relative url
    if ( result = @match path )?
      console.log result
      { data, bindings } = result
      try
        @handlers[data.name] { path, data, bindings }, context
      catch _error
        console.warn _error
        throw error "handler failed for [#{ path }]"
    else
      throw error "dispatch: no matching route for [#{ path }]"

  # TODO remove parameters that are empty strings
  link: ({ name, query, parameters }) ->
    query ?= { name }
    origin = window.location.href    
    route = @router.routes.find ( route ) -> Obj.query query, route.data
    if route?
      path = encode route.template, ( parameters ? {} )  
      new URL path, origin
    else
      console.warn "no matching route for [ #{ name } ]"
      new URL "/", origin

  push: ({ url, name, parameters, state }) ->
    url ?= @link { name, parameters }
    window.history.pushState state, "", url.href

  replace: ({ url, name, parameters, state }) ->
    url ?= @link { name, parameters }
    window.history.replaceState state, "", url.href

  browse: ({ url, name, parameters, state }) ->
    url ?= @link { name, parameters }
    url = @normalize url
    if isSameOrigin url
      unless isCurrentLocation url
        @push { url, state }
        @dispatch { url }
    else
      window.open url

# add convenience class methods
for name in ( Object.getOwnPropertyNames PageRouter:: )
  if name != "constructor"
    value = PageRouter::[ name ]
    if Type.isFunction value
      PageRouter[ name ] ?= Fn.detach value

hasPageScheme = ( url ) ->
  ( Type.isType URL, url ) &&
    url.protocol == "page:"

generic normalize,
  ( Type.isType PageRouter ),
  Type.isString,
  ( router, url ) -> normalize router, new URL url

generic normalize,
  ( Type.isType PageRouter ),
  ( Type.isType URL ),
  ( router, url ) -> url

generic normalize,
  ( Type.isType PageRouter ),
  hasPageScheme,
  ( router, url ) ->
    # TODO this should probably be based on a template?
    # see also Render.link in Vega Generators
    [ resource, action ] = url.pathname.split "/"
    # this probably isn't quite right...
    PageRouter.link router,
      query: { resource, action }
      parameters: Object.fromEntries url.searchParams

export default PageRouter
