// Categories HTTP handlers — mirrors ItemsController pattern
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

// ─── Handlers ───────────────────────────────────────────────────────────────────────────────────

let list = (~svc: CategoryService.t): Handler.t =>
  async (_req, _params) =>
    svc.findAll()
    ->Result.map(cats => cats->Array.map(Category.toJson)->Js.Json.array)
    ->AppError.toResponse

let get = (~svc: CategoryService.t): Handler.t =>
  async (_req, params) =>
    getIdParam(params)
    ->Result.flatMap(svc.findById)
    ->Result.map(Category.toJson)
    ->AppError.toResponse

let create = (~svc: CategoryService.t): Handler.t =>
  async (req, _params) => {
    let json = await req->Bun.json
    json
    ->Schemas.parseCategoryBody
    ->Result.flatMap(inputs =>
      switch inputs {
      | [single] => svc.insert(single)->Result.map(cat => [cat])
      | many     => svc.insertMany(many)
      }
    )
    ->Result.map(cats => cats->Array.map(Category.toJson)->Js.Json.array)
    ->AppError.toResponse
  }

let replace = (~svc: CategoryService.t): Handler.t =>
  async (req, params) => {
    let json = await req->Bun.json
    getIdParam(params)
    ->Result.flatMap(id =>
      json
      ->Schemas.parseCategoryReplace
      ->Result.map(input => ({id, name: input.name, description: input.description}: Schema.Categories.replaceRow))
      ->Result.flatMap(svc.replace)
    )
    ->Result.map(Category.toJson)
    ->AppError.toResponse
  }

let replaceMany = (~svc: CategoryService.t): Handler.t =>
  async (req, _params) => {
    let json = await req->Bun.json
    json
    ->Schemas.parseCategoryReplaceMany
    ->Result.flatMap(svc.replaceMany)
    ->Result.map(cats => cats->Array.map(Category.toJson)->Js.Json.array)
    ->AppError.toResponse
  }

let patch = (~svc: CategoryService.t): Handler.t =>
  async (req, params) => {
    let json = await req->Bun.json
    getIdParam(params)
    ->Result.flatMap(id =>
      json
      ->Schemas.parseCategoryPatch
      ->Result.flatMap(input => svc.patch(id, input))
    )
    ->Result.map(Category.toJson)
    ->AppError.toResponse
  }

let delete = (~svc: CategoryService.t): Handler.t =>
  async (_req, params) =>
    getIdParam(params)
    ->Result.flatMap(svc.delete)
    ->Result.map(_ => Js.Json.null)
    ->AppError.toResponse

let deleteMany = (~svc: CategoryService.t): Handler.t =>
  async (req, _params) => {
    let json = await req->Bun.json
    json
    ->Schemas.parseCategoryDeleteMany
    ->Result.flatMap(svc.deleteMany)
    ->Result.map(_ => Js.Json.null)
    ->AppError.toResponse
  }
