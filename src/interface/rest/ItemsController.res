// ItemsController: HTTP handlers using Bun.serve
// All handlers take Fetch API Request, return Fetch API Response

open BunServer

// ============================================================================
// Helper: Parse JSON body with error handling
// ============================================================================

let parseJsonBody = async (req: request): promise<result<'a, string>> => {
  try {
    let body = await req->json
    Ok(body)->Promise.resolve
  } catch {
  | _ => Error("Invalid JSON")->Promise.resolve
  }
}

// ============================================================================
// Helper: Parse URL parameters
// ============================================================================

let getIdParam = (url: URL.t): result<int, string> => {
  // URL pathname is "/rest/items/:id"
  // We extract the ID from the route params passed by Router
  // For now, simplified: just try to parse last segment
  let pathname = url->URL.pathname
  let parts = pathname->String.split("/")->Array.filter(s => s != "")
  
  switch parts {
  | [_, _, id] =>
    switch Int.fromString(id) {
    | Some(num) => Ok(num)
    | None => Error("Invalid ID format")
    }
  | _ => Error("Missing ID parameter")
  }
}

// ============================================================================
// GET /rest/items
// ============================================================================

let list = async (req: request): promise<response> => {
  switch await ItemService.getAll() {
  | Ok(items) =>
    let responses = items->Array.map(ItemDto.toResponse)
    json(~status=200, {"data": responses})->Promise.resolve
  | Error(err) =>
    let errorResp = AppError.toResponse(err)
    json(~status=errorResp["status"], errorResp)->Promise.resolve
  }
}

// ============================================================================
// GET /rest/items/:id
// ============================================================================

let get = async (req: request): promise<response> => {
  try {
    let url = URL.make(req->url)
    switch getIdParam(url) {
    | Error(msg) =>
      let errorResp = AppError.toResponse(AppError.internal(msg))
      json(~status=400, errorResp)->Promise.resolve
    | Ok(id) =>
      switch await ItemService.getOne(id) {
      | Ok(item) =>
        let response = ItemDto.toResponse(item)
        json(~status=200, {"data": response})->Promise.resolve
      | Error(err) =>
        let errorResp = AppError.toResponse(err)
        json(~status=errorResp["status"], errorResp)->Promise.resolve
      }
    }
  } catch {
  | _ =>
    let errorResp = AppError.toResponse(AppError.internal("Invalid request"))
    json(~status=400, errorResp)->Promise.resolve
  }
}

// ============================================================================
// POST /rest/items
// ============================================================================

let create = async (req: request): promise<response> => {
  try {
    switch await parseJsonBody(req) {
    | Error(msg) =>
      let errorResp = AppError.toResponse(AppError.internal(msg))
      json(~status=400, errorResp)->Promise.resolve
    | Ok(body) =>
      switch ItemDto.validateCreateItem(body) {
      | Error(msg) =>
        let errorResp = AppError.toResponse(AppError.validationFailed([msg]))
        json(~status=400, errorResp)->Promise.resolve
      | Ok(input) =>
        switch await ItemService.create(input) {
        | Ok(item) =>
          let response = ItemDto.toResponse(item)
          json(~status=201, {"data": response})->Promise.resolve
        | Error(err) =>
          let errorResp = AppError.toResponse(err)
          json(~status=errorResp["status"], errorResp)->Promise.resolve
        }
      }
    }
  } catch {
  | _ =>
    let errorResp = AppError.toResponse(AppError.internal("Request parsing failed"))
    json(~status=400, errorResp)->Promise.resolve
  }
}

// ============================================================================
// PUT /rest/items/:id
// ============================================================================

let update = async (req: request): promise<response> => {
  try {
    let url = URL.make(req->url)
    switch getIdParam(url) {
    | Error(msg) =>
      let errorResp = AppError.toResponse(AppError.internal(msg))
      json(~status=400, errorResp)->Promise.resolve
    | Ok(id) =>
      switch await parseJsonBody(req) {
      | Error(msg) =>
        let errorResp = AppError.toResponse(AppError.internal(msg))
        json(~status=400, errorResp)->Promise.resolve
      | Ok(body) =>
        switch ItemDto.validateUpdateItem(body) {
        | Error(msg) =>
          let errorResp = AppError.toResponse(AppError.validationFailed([msg]))
          json(~status=400, errorResp)->Promise.resolve
        | Ok(input) =>
          switch await ItemService.update(id, input) {
          | Ok(item) =>
            let response = ItemDto.toResponse(item)
            json(~status=200, {"data": response})->Promise.resolve
          | Error(err) =>
            let errorResp = AppError.toResponse(err)
            json(~status=errorResp["status"], errorResp)->Promise.resolve
          }
        }
      }
    }
  } catch {
  | _ =>
    let errorResp = AppError.toResponse(AppError.internal("Invalid request"))
    json(~status=400, errorResp)->Promise.resolve
  }
}

// ============================================================================
// DELETE /rest/items/:id
// ============================================================================

let delete = async (req: request): promise<response> => {
  try {
    let url = URL.make(req->url)
    switch getIdParam(url) {
    | Error(msg) =>
      let errorResp = AppError.toResponse(AppError.internal(msg))
      json(~status=400, errorResp)->Promise.resolve
    | Ok(id) =>
      switch await ItemService.delete(id) {
      | Ok() => empty(~status=204)->Promise.resolve
      | Error(err) =>
        let errorResp = AppError.toResponse(err)
        json(~status=errorResp["status"], errorResp)->Promise.resolve
      }
    }
  } catch {
  | _ =>
    let errorResp = AppError.toResponse(AppError.internal("Invalid item ID"))
    json(~status=400, errorResp)->Promise.resolve
  }
}
