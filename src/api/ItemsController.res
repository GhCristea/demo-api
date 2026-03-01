// Items HTTP handlers
// Uniform type: (request, params) => promise<response>
// Each handler is a single -> pipeline — parse, process, respond
// No JSON serialization here — Item.toJson / Category.toJson own that

type handler = (Bun.request, Js.Dict.t<string>) => promise<Bun.response>

// ─── Param helpers ────────────────────────────────────────────────────────────────

let getIdParam = (params: Js.Dict.t<string>): result<int, AppError.t> =>
  params
  ->Js.Dict.get("id")
  ->Result.fromOption(AppError.BadRequest("Missing id"))
  ->Result.flatMap(s =>
    Int.fromString(s)->Result.fromOption(AppError.BadRequest("id must be an integer"))
  )

// Extracts ?search= and ?limit= from the raw URL query string
let getListParams = (rawUrl: string): Schema.Items.listParams => {
  let urlObj = Bun.makeUrl(rawUrl)
  let search = Bun.searchParam(urlObj, "search")->Js.Nullable.toOption
  let limit  =
    Bun.searchParam(urlObj, "limit")
    ->Js.Nullable.toOption
    ->Option.flatMap(Int.fromString)
  {search, limit}
}

// ─── Handlers ─────────────────────────────────────────────────────────────────────

// GET /rest/items?search=&limit=
let list = async (req: Bun.request, _params: Js.Dict.t<string>): promise<Bun.response> =>
  ServiceRegistry.items.contents.findAll(getListParams(req->Bun.url))
  ->Result.map(items => items->Js.Array2.map(Item.toJson)->Js.Json.array)
  ->AppError.toResponse

// GET /rest/items/:id
let get = async (_req: Bun.request, params: Js.Dict.t<string>): promise<Bun.response> =>
  getIdParam(params)
  ->Result.flatMap(ServiceRegistry.items.contents.findById)
  ->Result.map(Item.toJson)
  ->AppError.toResponse

// GET /rest/items/:id/categories
let getCategories = async (_req: Bun.request, params: Js.Dict.t<string>): promise<Bun.response> =>
  getIdParam(params)
  ->Result.flatMap(ServiceRegistry.categories.contents)
  ->Result.map(Category.toJson)
  ->AppError.toResponse

// POST /rest/items — accepts single object or array
let create = async (req: Bun.request, _params: Js.Dict.t<string>): promise<Bun.response> => {
  let json = await req->Bun.json
  json
  ->Schemas.parseCreateBody
  ->Result.flatMap(inputs =>
    switch inputs {
    | [single] => ServiceRegistry.items.contents.insert(single)->Result.map(item => [item])
    | many     => ServiceRegistry.items.contents.insertMany(many)
    }
  )
  ->Result.map(items => items->Js.Array2.map(Item.toJson)->Js.Json.array)
  ->AppError.toResponse
}

// PUT /rest/items/:id
let replace = async (req: Bun.request, params: Js.Dict.t<string>): promise<Bun.response> => {
  let json = await req->Bun.json
  getIdParam(params)
  ->Result.flatMap(id =>
    json
    ->Schemas.parseReplace
    ->Result.map(input => ({id, name: input.name, description: input.description, categoryId: input.categoryId}: Schema.Items.replaceRow))
    ->Result.flatMap(ServiceRegistry.items.contents.replace)
  )
  ->Result.map(Item.toJson)
  ->AppError.toResponse
}

// PUT /rest/items — bulk full replace
let replaceMany = async (req: Bun.request, _params: Js.Dict.t<string>): promise<Bun.response> => {
  let json = await req->Bun.json
  json
  ->Schemas.parseReplaceMany
  ->Result.flatMap(ServiceRegistry.items.contents.replaceMany)
  ->Result.map(items => items->Js.Array2.map(Item.toJson)->Js.Json.array)
  ->AppError.toResponse
}

// DELETE /rest/items/:id
let delete = async (_req: Bun.request, params: Js.Dict.t<string>): promise<Bun.response> =>
  getIdParam(params)
  ->Result.flatMap(ServiceRegistry.items.contents.delete)
  ->Result.map(_ => Js.Json.null)
  ->AppError.toResponse

// DELETE /rest/items — bulk
let deleteMany = async (req: Bun.request, _params: Js.Dict.t<string>): promise<Bun.response> => {
  let json = await req->Bun.json
  json
  ->Schemas.parseDeleteMany
  ->Result.flatMap(ServiceRegistry.items.contents.deleteMany)
  ->Result.map(_ => Js.Json.null)
  ->AppError.toResponse
}
