// ItemsRouter: Route registration
// Maps HTTP paths to controller handlers

open Express

type router

@module("express")
external router: unit => router = "Router"

@send
external getRoute: (router, string, requestHandler) => unit = "get"

@send
external postRoute: (router, string, requestHandler) => unit = "post"

@send
external putRoute: (router, string, requestHandler) => unit = "put"

@send
external deleteRoute: (router, string, requestHandler) => unit = "delete"

// ============================================================================
// Route Definitions
// ============================================================================

let itemRouter = (): router => {
  let r = router()

  // GET /rest/items
  r->getRoute("/", ItemsController.list)

  // GET /rest/items/:id
  r->getRoute("/:id", ItemsController.get)

  // POST /rest/items
  r->postRoute("/", ItemsController.create)

  // PUT /rest/items/:id
  r->putRoute("/:id", ItemsController.update)

  // DELETE /rest/items/:id
  r->deleteRoute("/:id", ItemsController.delete)

  r
}
