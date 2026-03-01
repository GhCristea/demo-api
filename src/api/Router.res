// Request router
// All routes are under /rest prefix — matches .rest file source of truth
// Exact routes matched first, then parameterised routes
// extractParams returns None if segment count or literal segments don't match

let extractParams = (pattern: string, path: string): option<Js.Dict.t<string>> => {
  let pp = pattern->String.split("/")->Array.filter(s => s !== "")
  let rp = path->String.split("/")->Array.filter(s => s !== "")
  if Array.length(pp) !== Array.length(rp) {
    None
  } else {
    let params = Js.Dict.empty()
    let matched = ref(true)
    pp->Array.forEachWithIndex((pat, i) =>
      if String.startsWith(pat, ":") {
        params->Js.Dict.set(String.sliceToEnd(pat, ~start=1), rp->Array.getUnsafe(i))
      } else if pat !== rp->Array.getUnsafe(i) {
        matched := false
      }
    )
    matched.contents ? Some(params) : None
  }
}

type matched = {
  handler: ItemsController.handler,
  params:  Js.Dict.t<string>,
}

let match_ = (method: string, path: string): option<matched> =>
  switch (method, path) {
  // Exact routes first
  | ("GET",    "/rest/items") => Some({handler: ItemsController.list,        params: Js.Dict.empty()})
  | ("POST",   "/rest/items") => Some({handler: ItemsController.create,      params: Js.Dict.empty()})
  | ("PUT",    "/rest/items") => Some({handler: ItemsController.replaceMany, params: Js.Dict.empty()})
  | ("DELETE", "/rest/items") => Some({handler: ItemsController.deleteMany,  params: Js.Dict.empty()})
  // Parameterised routes — longest pattern first
  | ("GET", p) =>
    switch extractParams("/rest/items/:id/categories", p) {
    | Some(ps) => Some({handler: ItemsController.getCategories, params: ps})
    | None =>
      extractParams("/rest/items/:id", p)
      ->Option.map(ps => {handler: ItemsController.get, params: ps})
    }
  | ("PUT", p) =>
    extractParams("/rest/items/:id", p)
    ->Option.map(ps => {handler: ItemsController.replace, params: ps})
  | ("DELETE", p) =>
    extractParams("/rest/items/:id", p)
    ->Option.map(ps => {handler: ItemsController.delete, params: ps})
  | _ => None
  }

let dispatch = async (req: Bun.request): promise<Bun.response> => {
  let method = req->Bun.method
  let path   = req->Bun.url->Bun.getPathname
  switch match_(method, path) {
  | Some({handler, params}) => await handler(req, params)
  | None => AppError.toResponse(Error(AppError.NotFound("Route not found")))
  }
}
