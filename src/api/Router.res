// Request router
// Pattern matches on HTTP method + URL pathname
// extractParams handles :param segments — returns None if shape doesn't match

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
  params: Js.Dict.t<string>,
}

let match_ = (method: string, path: string): option<matched> =>
  switch (method, path) {
  | ("GET", "/items") => Some({handler: ItemsController.list, params: Js.Dict.empty()})
  | ("POST", "/items") => Some({handler: ItemsController.create, params: Js.Dict.empty()})
  | ("GET", p) =>
    extractParams("/items/:id", p)->Option.map(params => {handler: ItemsController.get, params})
  | ("PATCH", p) =>
    extractParams("/items/:id", p)->Option.map(params => {handler: ItemsController.update, params})
  | ("DELETE", p) =>
    extractParams("/items/:id", p)->Option.map(params => {handler: ItemsController.delete, params})
  | _ => None
  }

let dispatch = async (req: Bun.request): promise<Bun.response> => {
  let method = req->Bun.method
  let path = req->Bun.url->Bun.getPathname
  switch match_(method, path) {
  | Some({handler, params}) => await handler(req, params)
  | None =>
    AppError.toResponse(Error(AppError.NotFound("Route not found")))
  }
}
