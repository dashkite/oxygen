error = (message) -> new Error "oxgen: #{message}"

relative = (url) ->
  if /^[^\/]/.test url
    {pathname, search} = new URL url
    pathname + search
  else
    url

export {error, relative}
