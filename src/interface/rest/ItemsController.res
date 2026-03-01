// ItemsController: HTTP request handlers
// Bridges Express (HTTP layer) and ItemService (business logic)
// Handles: parsing requests, calling service, formatting responses

open Express

// ============================================================================
// GET /rest/items
// ============================================================================

let list = async (req: request, res: response, _next: next): promise<unit> => {
  switch await ItemService.getAll() {
  | Ok(items) =>
    let responses = items->Array.map(ItemDto.toResponse)
    let _ = res->status(200)->json({"data": responses})
    ()
  | Error(err) =>
    let errorResp = AppError.toResponse(err)
    let _ = res->status(errorResp["status"])->json(errorResp)
    ()
  }
}

// ============================================================================
// GET /rest/items/:id
// ============================================================================

let get = async (req: request, res: response, _next: next): promise<unit> => {
  try {
    let params = req->params
    let id = params["id"]->Int.fromString->Option.getExn

    switch await ItemService.getOne(id) {
    | Ok(item) =>
      let response = ItemDto.toResponse(item)
      let _ = res->status(200)->json({"data": response})
      ()
    | Error(err) =>
      let errorResp = AppError.toResponse(err)
      let _ = res->status(errorResp["status"])->json(errorResp)
      ()
    }
  } catch {
  | _ =>
    let errorResp = AppError.toResponse(AppError.internal("Invalid item ID"))
    let _ = res->status(400)->json(errorResp)
    ()
  }
}

// ============================================================================
// POST /rest/items
// ============================================================================

let create = async (req: request, res: response, _next: next): promise<unit> => {
  try {
    let body = req->body

    switch ItemDto.validateCreateItem(body) {
    | Ok(input) =>
      switch await ItemService.create(input) {
      | Ok(item) =>
        let response = ItemDto.toResponse(item)
        let _ = res->status(201)->json({"data": response})
        ()
      | Error(err) =>
        let errorResp = AppError.toResponse(err)
        let _ = res->status(errorResp["status"])->json(errorResp)
        ()
      }
    | Error(msg) =>
      let errorResp = AppError.toResponse(AppError.validationFailed([msg]))
      let _ = res->status(400)->json(errorResp)
      ()
    }
  } catch {
  | _ =>
    let errorResp = AppError.toResponse(AppError.internal("Request parsing failed"))
    let _ = res->status(400)->json(errorResp)
    ()
  }
}

// ============================================================================
// PUT /rest/items/:id
// ============================================================================

let update = async (req: request, res: response, _next: next): promise<unit> => {
  try {
    let params = req->params
    let id = params["id"]->Int.fromString->Option.getExn
    let body = req->body

    switch ItemDto.validateUpdateItem(body) {
    | Ok(input) =>
      switch await ItemService.update(id, input) {
      | Ok(item) =>
        let response = ItemDto.toResponse(item)
        let _ = res->status(200)->json({"data": response})
        ()
      | Error(err) =>
        let errorResp = AppError.toResponse(err)
        let _ = res->status(errorResp["status"])->json(errorResp)
        ()
      }
    | Error(msg) =>
      let errorResp = AppError.toResponse(AppError.validationFailed([msg]))
      let _ = res->status(400)->json(errorResp)
      ()
    }
  } catch {
  | _ =>
    let errorResp = AppError.toResponse(AppError.internal("Invalid request"))
    let _ = res->status(400)->json(errorResp)
    ()
  }
}

// ============================================================================
// DELETE /rest/items/:id
// ============================================================================

let delete = async (req: request, res: response, _next: next): promise<unit> => {
  try {
    let params = req->params
    let id = params["id"]->Int.fromString->Option.getExn

    switch await ItemService.delete(id) {
    | Ok() =>
      let _ = res->status(204)->send("")
      ()
    | Error(err) =>
      let errorResp = AppError.toResponse(err)
      let _ = res->status(errorResp["status"])->json(errorResp)
      ()
    }
  } catch {
  | _ =>
    let errorResp = AppError.toResponse(AppError.internal("Invalid item ID"))
    let _ = res->status(400)->json(errorResp)
    ()
  }
}
