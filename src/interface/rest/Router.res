// Router: Pure ReScript routing, no external framework
// Parses URL and method, dispatches to handlers
// CORS preflight handled here

// ============================================================================
// Route Matching
// ============================================================================

type method = [#GET | #POST | #PUT | #DELETE | #PATCH | #OPTIONS]

type route = {
  method: method,
  path: string, // e.g., "/rest/items/:id"
}

type routeMatch = {
  handler: BunServer.fetchHandler,
  params: Js.Dict.t<string>,
}

// Parse URL path and extract route parameters
// E.g., "/rest/items/123" with pattern "/rest/items/:id" -> {id: "123"}
let parseRoute = (pattern: string, actualPath: string): option<Js.Dict.t<string>> => {
  let patternParts = pattern->String.split("/")->Array.filter(s => s != "")
  let actualParts = actualPath->String.split("/")->Array.filter(s => s != "")

  if Array.length(patternParts) != Array.length(actualParts) {
    None
  } else {
    let params = Js.Dict.empty()
    let matches = ref(true)

    Array.forEachWithIndex(patternParts, (part, i) => {
      if matches.contents {
        if String.startsWith(~prefix=":", part) {
          // This is a parameter
          let paramName = String.slice(~from=1, part)
          Js.Dict.set(params, paramName, actualParts[i])
        } else if part != actualParts[i] {
          // Literal mismatch
          matches := false
        }
      }
    })

    matches.contents ? Some(params) : None
  }
}

// ============================================================================
// Router
// ============================================================================

type router = {
  mutable routes: array<(route, BunServer.fetchHandler)>,
}

let create = (): router => {
  {
    routes: [],
  }
}

let register = (
  router: router,
  method: method,
  path: string,
  handler: BunServer.fetchHandler,
): unit => {
  let route = {method, path}
  router.routes = Array.concat(router.routes, [(route, handler)])
}

// Parse HTTP method string to method variant
let parseMethod = (methodStr: string): option<method> => {
  switch methodStr->String.toUpperCase {
  | "GET" => Some(#GET)
  | "POST" => Some(#POST)
  | "PUT" => Some(#PUT)
  | "DELETE" => Some(#DELETE)
  | "PATCH" => Some(#PATCH)
  | "OPTIONS" => Some(#OPTIONS)
  | _ => None
  }
}

// Dispatch request to matching handler
let dispatch = async (router: router, req: BunServer.request): promise<option<BunServer.response>> => {
  // CORS preflight
  let requestMethod = req->BunServer.method->String.toUpperCase
  if requestMethod == "OPTIONS" {
    Some(BunServer.corsPreflightResponse())->Promise.resolve
  } else {
    let url = URL.make(req->BunServer.url)
    let pathname = url->URL.pathname

    // Find matching route
    let matchedRoute = ref(None)

    Array.forEach(router.routes, ((route, handler)) => {
      if Option.isNone(matchedRoute.contents) {
        switch parseMethod(requestMethod) {
        | Some(method) if method == route.method =>
          switch parseRoute(route.path, pathname) {
          | Some(params) =>
            matchedRoute := Some((handler, params))
          | None => ()
          }
        | _ => ()
        }
      }
    })

    switch matchedRoute.contents {
    | Some((handler, _params)) =>
      let response = await handler(req)
      Some(response)->Promise.resolve
    | None => None->Promise.resolve
    }
  }
}

// ============================================================================
// Convenience Functions
// ============================================================================

let get = (router: router, path: string, handler: BunServer.fetchHandler): unit => {
  register(router, #GET, path, handler)
}

let post = (router: router, path: string, handler: BunServer.fetchHandler): unit => {
  register(router, #POST, path, handler)
}

let put = (router: router, path: string, handler: BunServer.fetchHandler): unit => {
  register(router, #PUT, path, handler)
}

let delete = (router: router, path: string, handler: BunServer.fetchHandler): unit => {
  register(router, #DELETE, path, handler)
}

let patch = (router: router, path: string, handler: BunServer.fetchHandler): unit => {
  register(router, #PATCH, path, handler)
}
