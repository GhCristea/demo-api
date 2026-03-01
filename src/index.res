// Application entry point
// Initializes database, sets up Express, starts server

open Express

let main = async (): promise<unit> => {
  let app = express()
  let port = 3001

  // ========================================================================
  // Middleware
  // ========================================================================

  app->use(cors())
  app->use(json())

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
  // Routes
  // ========================================================================

  let itemRouter = ItemsRouter.itemRouter()
  app->useRouter("/rest/items", itemRouter)

  // ========================================================================
  // Error Handler (must be last)
  // ========================================================================

  let errorHandler: errorHandler = async (err, _req, res, _next) => {
    let message = switch err {
    | None => "Unknown error"
    | Some(e) => Js.Error.message(e)
    }

    let errorResp = AppError.toResponse(AppError.internal(message))
    let _ = res->status(errorResp["status"])->json(errorResp)
    ()
  }

  app->useErrorHandler(errorHandler)

  // ========================================================================
  // Start Server
  // ========================================================================

  app->listen(port, () => {
    Console.log(`[Server] Running on http://localhost:${Int.toString(port)}`)
  })

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
