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

  match: ( path ) -> @router.match path

  _normalize: ({ url, path, name, query, parameters, state }) ->
    path ?= do =>
      url ?= @link { name, query, parameters }
      url = if Type.isURL url then url else new URL url
      relative url
    url ?= new URL path, window.location.origin
    { 
      url, path, state 
      isSameOrigin: isSameOrigin url
      isCurrentLocation: isCurrentLocation url
    }

  normalize: ( context ) ->
    if context.isSameOrigin?
      context
    else @_normalize context
    
  dispatch: ( context, store ) ->
    context = @normalize context
    { path } = context
    if !( result = @match path )?
      throw error "dispatch: no matching route for [#{ path }]"
    else
      { data, bindings } = result
      try
        @handlers[data.name] { path, data, bindings }, store
      catch _error
        console.warn _error
        throw error "handler failed for [#{ path }]"

  # TODO remove parameters that are empty strings
  link: ({ name, query, parameters }) ->
    query ?= { name }
    origin = window.location.href    
    route = @router.routes.find ( route ) -> Obj.query query, route.data
    if route?
      path = encode route.template, ( parameters ? {} )  
      new URL path, origin
    else
      console.warn "no matching route for query", query
      new URL "/", origin

  push: ( context ) ->
    context = @normalize context
    window.history.pushState context.state, "", context.path

  replace: ( context ) ->
    context = @normalize context
    window.history.replaceState context.state, "", context.path

  browse: ( context ) ->
    context = @normalize context
    if context.isCurrentLocation
      return
    else if !context.isSameOrigin
      window.open context.url.href
    else
      @push context
      @dispatch context

  # TODO should redirect open external links in a new tab
  #      as we do with browse?
  redirect: ( context ) ->
    context = @normalize context
    if context.isCurrentLocation
      return
    else if !context.isSameOrigin
      window.open context.url.href
    else
      @replace context
      @dispatch context
  

# add convenience class methods
for name in ( Object.getOwnPropertyNames PageRouter:: )
  if name != "constructor"
    value = PageRouter::[ name ]
    if Type.isFunction value
      PageRouter[ name ] ?= Fn.detach value

export default PageRouter
