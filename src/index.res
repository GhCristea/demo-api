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
    BunServer.exit(1)
  }

  // ========================================================================
  // Request Handler
  // ========================================================================

  let handleRequest = async (req: BunServer.request): promise<BunServer.response> => {
    // Try to find a matching route
    switch await Router.dispatch(req) {
    | Some(response) => response->Promise.resolve
    | None =>
      // No route matched
      let errorResp = AppError.toResponse(AppError.NotFound("Route not found"))
      errorResp->Promise.resolve
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
    BunServer.exit(0)
  }

  BunServer.onExit(async () => {
    await handleShutdown()
  })
}

// Start the application
let _ = main()
