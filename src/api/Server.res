// HTTP server
// Starts Bun.serve wired to Router.dispatch
// Graceful shutdown: closes the db on process exit

let start = (~port: int, ~db: Bun.Sqlite.db): unit => {
  let _server = Bun.serve({
    fetch: Router.dispatch,
    port,
    hostname: "0.0.0.0",
  })
  Console.log(`[server] http://localhost:${Int.toString(port)}`)

  // Graceful shutdown — close db before process exits
  let _ = Node.Process.process["on"](
    "SIGINT",
    () => {
      Console.log("[server] shutting down")
      db->Bun.Sqlite.close
      Bun.exit(0)
    },
  )
}
