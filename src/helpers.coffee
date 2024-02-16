error = ( message ) -> new Error "oxgen: #{message}"

relative = ( url ) ->
  if /^[^\/]/.test url
    {pathname, search} = new URL url
    pathname + search
  else
    url

isSameOrigin = ( url ) ->
  window.location.origin == url.origin

isCurrentLocation = ( url ) ->
  window.location.href == url.href

export { 
  error
  relative
  isSameOrigin
  isCurrentLocation
}
