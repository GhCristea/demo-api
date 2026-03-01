// URL Router
// Pattern matching on METHOD + PATH
// Extracts route parameters and dispatches to handlers

type route = {
  method: string,
  pattern: string,
}

// ========================================================================
// Route Matching
// ========================================================================

// Parse path parameters from route pattern
// /items/:id matches GET /items/42 -> {id: "42"}
let extractParams = (pattern: string, path: string): option<Js.Dict.t<string>> => {
  let patternParts = pattern->Js.String2.split("/")->Js.Array2.filter(s => s !== "")
  let pathParts = path->Js.String2.split("/")->Js.Array2.filter(s => s !== "")

  if Js.Array2.length(patternParts) !== Js.Array2.length(pathParts) {
    None
  } else {
    let params = Js.Dict.empty()
    let matched = ref(true)

    for i in 0 to Js.Array2.length(patternParts) - 1 {
      let patternPart = patternParts->Js.Array2.unsafe_get(i)
      let pathPart = pathParts->Js.Array2.unsafe_get(i)

      if Js.String2.charAt(patternPart, 0) === ":" {
        // Parameter
        let paramName = Js.String2.slice(patternPart, ~from=1, ~to_=Js.String2.length(patternPart))
        params->Js.Dict.set(paramName, pathPart)
      } else if patternPart !== pathPart {
        // Static part doesn't match
        matched := false
      }
    }

    matched.contents ? Some(params) : None
  }
}

// Match request to route
type matchedRoute = {
  handler: ItemsController.handler,
  params: Js.Dict.t<string>,
}

let matchRoute = (method: string, path: string): option<matchedRoute> => {
  switch (method, path) {
  | ("GET", "/items") => Some({handler: ItemsController.list, params: Js.Dict.empty()})
  | ("POST", "/items") => Some({handler: ItemsController.create, params: Js.Dict.empty()})
  | ("GET", path) =>
    switch extractParams("/items/:id", path) {
    | Some(params) => Some({handler: ItemsController.get, params})
    | None => None
    }
  | ("PATCH", path) =>
    switch extractParams("/items/:id", path) {
    | Some(params) => Some({handler: ItemsController.update, params})
    | None => None
    }
  | ("DELETE", path) =>
    switch extractParams("/items/:id", path) {
    | Some(params) => Some({handler: ItemsController.delete, params})
    | None => None
    }
  | _ => None
  }
}

// ========================================================================
// Request Handler
// ========================================================================

let dispatch = async (req: BunServer.request): promise<option<BunServer.response>> => {
  let method = req->BunServer.method
  let url = req->BunServer.url
  
  // Extract path from URL (remove query string)
  let path = switch Js.String2.indexOf(url, "?") {
  | -1 => url
  | index => Js.String2.slice(url, ~from=0, ~to_=index)
  }

  switch matchRoute(method, path) {
  | Some(matched) =>
    let response = await matched.handler(req, matched.params)
    Some(response)->Promise.resolve
  | None => None->Promise.resolve
  }
}
