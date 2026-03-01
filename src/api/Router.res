// Request router — routes are a data structure, bound once at startup
// Adding a resource: push routes onto the array, no other changes needed
// extractParams is pure — no mutation

let extractParams = (pattern: string, path: string): option<Js.Dict.t<string>> => {
  let pp = pattern->String.split("/")->Array.filter(s => s !== "")
  let rp = path->String.split("/")->Array.filter(s => s !== "")
  if Array.length(pp) !== Array.length(rp) { None } else {
    Array.zip(pp, rp)
    ->Array.reduce(Some(Js.Dict.empty()), (acc, (pat, seg)) =>
      acc->Option.flatMap(params =>
        if String.startsWith(pat, ":") {
          params->Js.Dict.set(String.sliceToEnd(pat, ~start=1), seg)
          Some(params)
        } else if pat === seg { Some(params) }
        else { None }
      )
    )
  }
}

let make = (registry: ServiceRegistry.t): (Bun.request => promise<Bun.response>) => {
  let items  = registry.items
  let cats   = registry.categories

  // Exact routes first, parameterised after — longest patterns before shorter ones
  let routes: array<(string, string, Handler.t)> = [
    ("GET",    "/rest/items",                ItemsController.list(~svc=items)),
    ("POST",   "/rest/items",                ItemsController.create(~svc=items)),
    ("PUT",    "/rest/items",                ItemsController.replaceMany(~svc=items)),
    ("DELETE", "/rest/items",                ItemsController.deleteMany(~svc=items)),
    ("GET",    "/rest/items/:id/categories", ItemsController.getCategories(~svc=items, ~catSvc=cats)),
    ("GET",    "/rest/items/:id",            ItemsController.get(~svc=items)),
    ("PUT",    "/rest/items/:id",            ItemsController.replace(~svc=items)),
    ("DELETE", "/rest/items/:id",            ItemsController.delete(~svc=items)),
  ]

  async (req: Bun.request): promise<Bun.response> => {
    let method = req->Bun.method
    let path   = req->Bun.url->Bun.getPathname
    let found  = routes->Array.findMap(((m, pattern, handler)) =>
      if m === method {
        extractParams(pattern, path)->Option.map(params => (handler, params))
      } else { None }
    )
    switch found {
    | Some((handler, params)) => await handler(req, params)
    | None => AppError.toResponse(Error(AppError.NotFound("Route not found")))
    }
  }
}
