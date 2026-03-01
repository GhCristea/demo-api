// Items REST API handlers
// Polymorphic handlers with inline request parsing
// Type: request -> promise<response>

// ========================================================================
// Handler Type
// ========================================================================

type handler = BunServer.request => promise<BunServer.response>

// ========================================================================
// Helper: Read Request Body
// ========================================================================

let readBody = async (req: BunServer.request): promise<string> => {
  try {
    let body = await req->BunServer.text
    body->Promise.resolve
  } catch {
  | _ => ""->Promise.resolve
  }
}

// ========================================================================
// Helper: Extract URL Parameter
// ========================================================================

let getIdParam = (params: Js.Dict.t<string>, key: string): option<int> => {
  switch params->Js.Dict.get(key) {
  | Some(idStr) =>
    switch Belt.Int.fromString(idStr) {
    | Some(id) => Some(id)
    | None => None
    }
  | None => None
  }
}

// ========================================================================
// Handlers
// ========================================================================

// GET /items
let list = async (_req: BunServer.request): promise<BunServer.response> => {
  let result = await ItemService.default.list()
  switch result {
  | Ok(items) =>
    let json = Js.Json.array(items->Js.Array2.map(item =>
      Js.Json.object_(Js.Dict.fromArray([|
        ("id", Js.Json.number(Int.toFloat(item.id))),
        ("name", Js.Json.string(item.name)),
        ("description", switch item.description {
        | Some(desc) => Js.Json.string(desc)
        | None => Js.Json.null
        }),
        ("createdAt", Js.Json.number(item.createdAt)),
        ("updatedAt", Js.Json.number(item.updatedAt)),
      |]))
    ))
    BunServer.json(~status=200, json)->Promise.resolve
  | Error(err) => AppError.toResponse(err)->Promise.resolve
  }
}

// GET /items/:id
let get = async (req: BunServer.request, params: Js.Dict.t<string>): promise<BunServer.response> => {
  switch getIdParam(params, "id") {
  | Some(id) =>
    let result = await ItemService.default.get(id)
    switch result {
    | Ok(item) =>
      let json = Js.Json.object_(Js.Dict.fromArray([|
        ("id", Js.Json.number(Int.toFloat(item.id))),
        ("name", Js.Json.string(item.name)),
        ("description", switch item.description {
        | Some(desc) => Js.Json.string(desc)
        | None => Js.Json.null
        }),
        ("createdAt", Js.Json.number(item.createdAt)),
        ("updatedAt", Js.Json.number(item.updatedAt)),
      |]))
      BunServer.json(~status=200, json)->Promise.resolve
    | Error(err) => AppError.toResponse(err)->Promise.resolve
    }
  | None =>
    AppError.toResponse(AppError.NotFound("Invalid item ID"))->Promise.resolve
  }
}

// POST /items
let create = async (req: BunServer.request, _params: Js.Dict.t<string>): promise<BunServer.response> => {
  let body = await readBody(req)
  let parseResult = Schemas.parseCreateInput(body)
  switch parseResult {
  | Ok(input) =>
    let result = await ItemService.default.create(input)
    switch result {
    | Ok(item) =>
      let json = Js.Json.object_(Js.Dict.fromArray([|
        ("id", Js.Json.number(Int.toFloat(item.id))),
        ("name", Js.Json.string(item.name)),
        ("description", switch item.description {
        | Some(desc) => Js.Json.string(desc)
        | None => Js.Json.null
        }),
        ("createdAt", Js.Json.number(item.createdAt)),
        ("updatedAt", Js.Json.number(item.updatedAt)),
      |]))
      BunServer.json(~status=201, json)->Promise.resolve
    | Error(err) => AppError.toResponse(err)->Promise.resolve
    }
  | Error(errors) =>
    AppError.toResponse(AppError.ValidationError(errors))->Promise.resolve
  }
}

// PATCH /items/:id
let update = async (req: BunServer.request, params: Js.Dict.t<string>): promise<BunServer.response> => {
  switch getIdParam(params, "id") {
  | Some(id) =>
    let body = await readBody(req)
    let parseResult = Schemas.parseUpdateInput(body)
    switch parseResult {
    | Ok(input) =>
      let result = await ItemService.default.update(id, input)
      switch result {
      | Ok(item) =>
        let json = Js.Json.object_(Js.Dict.fromArray([|
          ("id", Js.Json.number(Int.toFloat(item.id))),
          ("name", Js.Json.string(item.name)),
          ("description", switch item.description {
          | Some(desc) => Js.Json.string(desc)
          | None => Js.Json.null
          }),
          ("createdAt", Js.Json.number(item.createdAt)),
          ("updatedAt", Js.Json.number(item.updatedAt)),
        |]))
        BunServer.json(~status=200, json)->Promise.resolve
      | Error(err) => AppError.toResponse(err)->Promise.resolve
      }
    | Error(errors) =>
      AppError.toResponse(AppError.ValidationError(errors))->Promise.resolve
    }
  | None =>
    AppError.toResponse(AppError.NotFound("Invalid item ID"))->Promise.resolve
  }
}

// DELETE /items/:id
let delete = async (_req: BunServer.request, params: Js.Dict.t<string>): promise<BunServer.response> => {
  switch getIdParam(params, "id") {
  | Some(id) =>
    let result = await ItemService.default.delete(id)
    switch result {
    | Ok(()) => BunServer.json(~status=204, Js.Json.null)->Promise.resolve
    | Error(err) => AppError.toResponse(err)->Promise.resolve
    }
  | None =>
    AppError.toResponse(AppError.NotFound("Invalid item ID"))->Promise.resolve
  }
}
