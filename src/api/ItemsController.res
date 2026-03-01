// Items HTTP handlers
// Uniform type: (request, params) => promise<response>
// Each handler is a single -> pipeline — parse, process, respond
// No JSON serialization here — Item.toJson owns that

type handler = (Bun.request, Js.Dict.t<string>) => promise<Bun.response>

let getIdParam = (params: Js.Dict.t<string>): result<int, AppError.t> =>
  params
  ->Js.Dict.get("id")
  ->Result.fromOption(AppError.BadRequest("Missing id"))
  ->Result.flatMap(s =>
    Int.fromString(s)->Result.fromOption(AppError.BadRequest("id must be an integer"))
  )

// GET /items
let list = async (_req: Bun.request, _params: Js.Dict.t<string>): promise<Bun.response> =>
  ServiceRegistry.items.list()
  ->Result.map(items => items->Js.Array2.map(Item.toJson)->Js.Json.array)
  ->AppError.toResponse

// GET /items/:id
let get = async (_req: Bun.request, params: Js.Dict.t<string>): promise<Bun.response> =>
  getIdParam(params)
  ->Result.flatMap(ServiceRegistry.items.get)
  ->Result.map(Item.toJson)
  ->AppError.toResponse

// POST /items
let create = async (req: Bun.request, _params: Js.Dict.t<string>): promise<Bun.response> => {
  let json = await req->Bun.json
  json
  ->Schemas.parseCreate
  ->Result.flatMap(ServiceRegistry.items.create)
  ->Result.map(Item.toJson)
  ->AppError.toResponse
}

// PATCH /items/:id
let update = async (req: Bun.request, params: Js.Dict.t<string>): promise<Bun.response> => {
  let json = await req->Bun.json
  getIdParam(params)
  ->Result.flatMap(id =>
    json
    ->Schemas.parseUpdate
    ->Result.flatMap(input => ServiceRegistry.items.update(id, input))
  )
  ->Result.map(Item.toJson)
  ->AppError.toResponse
}

// DELETE /items/:id
let delete = async (_req: Bun.request, params: Js.Dict.t<string>): promise<Bun.response> =>
  getIdParam(params)
  ->Result.flatMap(ServiceRegistry.items.delete)
  ->Result.map(_ => Js.Json.null)
  ->AppError.toResponse
