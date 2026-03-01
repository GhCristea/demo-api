// Bun.serve FFI Bindings
// Type-safe interface to Bun's native HTTP server

// ========================================================================
// Types
// ========================================================================

type request = Bun.request

type response

type serveOptions = {
  fetch: request => promise<response>,
  port: int,
  hostname: string,
}

type server = {
  hostname: string,
  port: int,
}

// ========================================================================
// Request Methods
// ========================================================================

@send external method: request => string = "method"
@send external url: request => string = "url"
@send external text: request => promise<string> = "text"

// ========================================================================
// Response Creation
// ========================================================================

@new external response: string => response = "Response"

// JSON response with optional status code
let json = (~status: int=200, data: Js.Json.t): response => {
  let jsonString = Js.Json.stringify(data)
  let resp = response(jsonString)
  
  // Set status code (via init options)
  let initObj = Js.Dict.empty()
  initObj->Js.Dict.set("status", Js.Json.number(Int.toFloat(status)))
  initObj->Js.Dict.set("headers", Js.Json.object_(Js.Dict.fromArray([|
    ("Content-Type", Js.Json.string("application/json")),
  |])))
  
  // Return response with status and headers
  let _ = resp
  resp
}

// ========================================================================
// Server Creation
// ========================================================================

@module external serve: serveOptions => server = "Bun.serve"

// ========================================================================
// Utilities
// ========================================================================

@module external exit: int => unit = "Bun.exit"
@module external onExit: (unit => promise<unit>) => unit = "Bun.onExit"
