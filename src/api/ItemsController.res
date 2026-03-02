// Items HTTP handlers
// Each handler takes ~svc explicitly — no global registry access
// Returns Handler.t (curried) so Router can bind at startup

// ─── Param helpers ──────────────────────────────────────────────────────────────────────────────

let getIdParam = (params: Js.Dict.t<string>): result<int, AppError.t> =>
  params
  ->Js.Dict.get("id")
  ->Result.fromOption(AppError.BadRequest("Missing id"))
  ->Result.flatMap(s =>
    Int.fromString(s)->Result.fromOption(AppError.BadRequest("id must be an integer"))
  )

let getListParams = (rawUrl: string): Schema.Items.listParams => {
  let u      = Bun.makeUrl(rawUrl)
  let search = Bun.searchParam(u, "search")->Js.Nullable.toOption
  let limit  = Bun.searchParam(u, "limit")->Js.Nullable.toOption->Option.flatMap(Int.fromString)
  {search, limit}
}

// ─── Handlers ───────────────────────────────────────────────────────────────────────────────────

let list = (~svc: ItemService.t): Handler.t =>
  async (req, _params) =>
    svc.findAll(getListParams(req->Bun.url))
    ->Result.map(items => items->Array.map(Item.toJson)->Js.Json.array)
    ->AppError.toResponse

let get = (~svc: ItemService.t): Handler.t =>
  async (_req, params) =>
    getIdParam(params)
    ->Result.flatMap(svc.findById)
    ->Result.map(Item.toJson)
    ->AppError.toResponse

let getCategories = (~svc: ItemService.t, ~catSvc: CategoryService.t): Handler.t =>
  async (_req, params) =>
    getIdParam(params)
    ->Result.flatMap(catSvc.findByItemId)
    ->Result.map(Category.toJson)
    ->AppError.toResponse

let create = (~svc: ItemService.t): Handler.t =>
  async (req, _params) => {
    let json = await req->Bun.json
    json
    ->Schemas.parseCreateBody
    ->Result.flatMap(inputs =>
      switch inputs {
      | [single] => svc.insert(single)->Result.map(item => [item])
      | many     => svc.insertMany(many)
      }
    )
    ->Result.map(items => items->Array.map(Item.toJson)->Js.Json.array)
    ->AppError.toResponse
  }

let replace = (~svc: ItemService.t): Handler.t =>
  async (req, params) => {
    let json = await req->Bun.json
    getIdParam(params)
    ->Result.flatMap(id =>
      json
      ->Schemas.parseReplace
      ->Result.map(input => ({id, name: input.name, description: input.description, categoryId: input.categoryId}: Schema.Items.replaceRow))
      ->Result.flatMap(svc.replace)
    )
    ->Result.map(Item.toJson)
    ->AppError.toResponse
  }

let replaceMany = (~svc: ItemService.t): Handler.t =>
  async (req, _params) => {
    let json = await req->Bun.json
    json
    ->Schemas.parseReplaceMany
    ->Result.flatMap(svc.replaceMany)
    ->Result.map(items => items->Array.map(Item.toJson)->Js.Json.array)
    ->AppError.toResponse
  }

let patch = (~svc: ItemService.t): Handler.t =>
  async (req, params) => {
    let json = await req->Bun.json
    getIdParam(params)
    ->Result.flatMap(id =>
      json
      ->Schemas.parsePatch
      ->Result.flatMap(input => svc.patch(id, input))
    )
    ->Result.map(Item.toJson)
    ->AppError.toResponse
  }

let delete = (~svc: ItemService.t): Handler.t =>
  async (_req, params) =>
    getIdParam(params)
    ->Result.flatMap(svc.delete)
    ->Result.map(_ => Js.Json.null)
    ->AppError.toResponse

let deleteMany = (~svc: ItemService.t): Handler.t =>
  async (req, _params) => {
    let json = await req->Bun.json
    json
    ->Schemas.parseDeleteMany
    ->Result.flatMap(svc.deleteMany)
    ->Result.map(_ => Js.Json.null)
    ->AppError.toResponse
  }
