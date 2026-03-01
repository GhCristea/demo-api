// Bun.serve FFI bindings
// Native HTTP server with zero external dependencies
// Built-in to Bun runtime

// ============================================================================
// Types
// ============================================================================

type request = Request.t
type response = Response.t

type fetchHandler = request => promise<response>

type serverOptions = {
  fetch: fetchHandler,
  port: int,
  hostname: string,
}

type server

// ============================================================================
// Request Methods
// ============================================================================

// URL from request
@get
external url: request => string = "url"

// HTTP method
@get
external method: request => string = "method"

// Parse JSON body (built-in to Fetch API)
@send
external json: request => promise<'a> = "json"

// Parse text body
@send
external text: request => promise<string> = "text"

// ============================================================================
// Response Construction
// ============================================================================

// Create response from body and init
@new
external response: (string, {..}) => response = "Response"

// Create response from JSON
let json = (~status=200, data: 'a): response => {
  let body = Bun.JSON.stringify(data)
  let init = {
    "status": status,
    "headers": {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type",
    },
  }
  response(body, init)
}

// Create empty response (204 No Content)
let empty = (~status=204): response => {
  let init = {
    "status": status,
    "headers": {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type",
    },
  }
  response("", init)
}

// Handle CORS preflight
let corsPreflightResponse = (): response => {
  let init = {
    "status": 204,
    "headers": {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type",
      "Access-Control-Max-Age": "86400",
    },
  }
  response("", init)
}

// ============================================================================
// Bun.serve
// ============================================================================

@module("bun")
external serve: serverOptions => server = "serve"
