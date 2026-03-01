// Application entry point
// Pure Bun.serve + ReScript, zero external HTTP dependencies

let main = async (): promise<unit> => {
  let port = 3001
  let hostname = "0.0.0.0"

  // ========================================================================
  // Database Initialization
  // ========================================================================

  Console.log("[Server] Initializing database...")

  switch await AppDataSource.initialize() {
  | Ok(_) => Console.log("[Server] Database initialized successfully")
  | Error(msg) =>
    Console.error(`[Server] Database initialization failed: ${msg}`)
    Bun.exit(1)
  }

  // ========================================================================
  // Router Setup
  // ========================================================================

  let router = Router.create()

  // Items endpoints
  Router.get(router, "/rest/items", ItemsController.list)
  Router.get(router, "/rest/items/:id", ItemsController.get)
  Router.post(router, "/rest/items", ItemsController.create)
  Router.put(router, "/rest/items/:id", ItemsController.update)
  Router.delete(router, "/rest/items/:id", ItemsController.delete)

  // ========================================================================
  // Request Handler
  // ========================================================================

  let handleRequest = async (req: BunServer.request): promise<BunServer.response> => {
    // Try to find a matching route
    switch await Router.dispatch(router, req) {
    | Some(response) => response->Promise.resolve
    | None =>
      // No route matched
      let errorResp = AppError.toResponse(AppError.internal("Not Found"))
      BunServer.json(~status=404, errorResp)->Promise.resolve
    }
  }

  // ========================================================================
  // Start Bun Server
  // ========================================================================

  let _server = BunServer.serve({
    fetch: handleRequest,
    port,
    hostname,
  })

  Console.log(`[Server] Running on http://localhost:${Int.toString(port)}`)

  // ========================================================================
  // Graceful Shutdown
  // ========================================================================

  let handleShutdown = async (): promise<unit> => {
    Console.log("\n[Server] Shutting down...")
    AppDataSource.destroy()
    Bun.exit(0)
  }

  Bun.onExit(async () => {
    await handleShutdown()
  })
}

// Start the application
let _ = main()
