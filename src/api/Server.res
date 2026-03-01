// HTTP server
// Starts Bun.serve wired to Router.make(registry)
// Graceful shutdown: closes the db on process exit

let start = (~port: int, ~db: Bun.Sqlite.db, ~registry: ServiceRegistry.t): unit => {
  let _server = Bun.serve({
    fetch: Router.make(registry),
    port,
    hostname: "0.0.0.0",
  })
  Console.log(`[server] http://localhost:${Int.toString(port)}`)
  let _ = Node.Process.process["on"]("SIGINT", () => {
    Console.log("[server] shutting down")
    db->Bun.Sqlite.close
    Bun.exit(0)
  })
}
