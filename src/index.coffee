import * as Fn  from "@dashkite/joy/function"
import { generic }  from "@dashkite/joy/generic"
import * as Type  from "@dashkite/joy/type"
import { events } from "@dashkite/joy/iterable"
import { Router } from "@dashkite/url-router"
import { navigate } from "@dashkite/navigate"
import { encode } from "@dashkite/url-codex"
import { error, relative, isSameOrigin, isCurrentLocation } from "./helpers"

# implementation is below
# declared here so we can reference it
# in the PageRouter class definition
normalize = generic name: "Oxygen.normalize"

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
    queueMicrotask =>
      @dispatch url: window.location.href

  append: ( template, data, handler ) ->
    @router.append { template, data }
    @handlers[data.name] = handler

  prepend: ( template, data, handler ) ->
    @router.prepend { template, data }
    @handlers[data.name] = handler

  # convenience / backward compatibility
  add: ( template, data, handler ) -> 
    @append template, data, handler

  normalize: ( url ) -> normalize @, url

  match: ( path ) -> @router.match path

  dispatch: ({ url, name, parameters }, context) ->
    url ?= @link { name, parameters }
    url = @normalize url
    path = relative url
    if ( result = @match path )?
      { data, bindings } = result
      try
        @handlers[data.name] { path, data, bindings }, context
      catch _error
        console.warn _error
        throw error "handler failed for [#{ url }]"
    else
      throw error "dispatch: no matching route for [#{ url }]"

  # TODO remove parameters that are empty strings
  link: ({ name, parameters }) ->
    origin = window.location.href    
    route = @router.routes.find ( route ) -> route.data.name == name
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
      name: "#{ action }-#{ resource}"
      parameters: Object.fromEntries url.searchParams

export default PageRouter
