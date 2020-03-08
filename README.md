# Oxygen
Browser-friendly URL-template-based routing.

Oxgen maps an [RFC 6570 URL template](https://tools.ietf.org/html/rfc6570) to a function.

(Code examples are CoffeeScript because we prefer it, but Oxygen is transpiled into modern JavaScript.)

```coffeescript
import Router from "@dashkite/oxygen"

router = Router.create()

Router.add router, "/hello/{name}",
  name: "greeting"
  ({bindings}) ->
    console.log "Hello, #{bindings.name}"

dispatch "/hello/dan"
```

By itself, this is doesn't do much, but that's the idea: you can put anything in the function, and thus use routes for whatever you want, using whichever libraries or frameworks you want.

The [Neon](https://github.com/dashkite/neon) library provides [combinators](https://raganwald.com/2012/12/01/combinators-in-js.html) for dynamically rendering and updating Web pages. We can use Neon to construction the handlers for our routes.

## Installation

```
npm i @dashkite/oxygen
```

Oxygen is intended to be used in the browser via a bundler like Web Pack. It may also be used in a server context, such as server-side rendering. The only parts of the API that depend on the DOM API are those that manipulate browser history: `push`, `replace`, and `browse`.

## API

### `create`

Create an instance of a router.

### `add router, template, data, handler`

Add a route for the given template, it with the given data and the handler.

The handler should take an object with three properties:

- `path` - the original path that matched the template
- `data` - the data properties associated with the route
- `bindings`- the values destructured from the template

The `name` property for the `data` element is required.

### `match router, path`

Primarily intended for internal use, this will return the bindings and data for the route matching the given path.

### `dispatch router, description`

Fires the handler that matches the description. The description may be a URL or path or a name with parameters. The latter case allows you to dispatch a route by name instead of by path. This is useful when you want to logically reference a route.

#### Examples

##### Dispatch Via Path

```coffeescript
dispatch router, url: "/hello/dan"
```

##### Dispatch Via Name With Parameters

```coffeescript
dispatch router, name: "greeting", parameters: name: "dan"
```

### `link router, description`

Returns the URL for the given description. The description must include the route name and may include parameters.

#### Example

```coffeescript
assert.equal "/hello/dan",
  link router, name: "greeting", parameters: name: "dan"
```

### `push router, description`

Pushes a URL onto the browser history (also known as [push state](https://developer.mozilla.org/en-US/docs/Web/API/History_API/Working_with_the_History_API)). Description must include either a URL or a name with parameters. It may also include state, although Oxygen doesn't make use of this feature directly.

#### Example

```coffeescript
push router, url: "/hello/jay"
```

### `replace router, description`

Replaces the current URL in the browser history. See `push`.

### `browse router, description`

Like `push` followed by `dispatch`: pushes a URL onto the browser history and dispatches it.
