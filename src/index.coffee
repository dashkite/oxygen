import {curry, tee} from "panda-garden"
import {Router} from "panda-router"
import TemplateParser from "url-template"

class PageRouter
  constructor: ({@router = new Router, @handlers = {}} = {}) ->

create  = -> new PageRouter arguments...

add = curry tee ({router, handlers}, template, data, handler) ->
  router.add {template, data}
  handlers[data.name] = handler

match = curry ({router}, path) -> router.match path

# TODO this seems like it belongs somewhere else
relative = (url) ->
  if /^[^\/]/.test url
    {pathname, search} = new URL url
    pathname + search
  else
    url

dispatch = curry ($, {url, name, parameters}) ->
  {router, handlers} = $
  url ?= link {name, parameters}
  path = relative url
  try
    {data, bindings} = match $, path
  catch error
    console.warn "Failed to match '#{url}'"
    throw error
  try
    handlers[data.name] {path, data, bindings}
  catch error
    console.warn "No handler defined for '#{data.name}'"
    throw error

link = curry ({router}, {name, parameters}) ->
  for route in router.routes
    if route.data.name == name
      return TemplateParser
        .parse route.template
        .expand parameters ? {}

  console.warn "link: no page matching '#{name}'"

push = curry ($, {url, name, parameters, state}) ->
  url ?= link $, {name, parameters}
  window.history.pushState state, "", url

replace = curry ($, {url, name, parameters, state}) ->
  url ?= link $, {name, parameters}
  window.history.replaceState state, "", url

browse = curry ($, {url, name, parameters, state}) ->
  url ?= link $, {name, parameters}
  # pushState will throw if undefined
  try
    push $, {url, state}
    dispatch $, {url}
  catch error
    console.warn error
    # For non-local URLs, open the link in a new tab.
    window.open url

export {create, add, match, dispatch, link, push, replace, browse}
