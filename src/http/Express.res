// Express FFI bindings
// Minimal, focused on the operations we use
// We keep Express (lower risk) instead of switching to Bun.serve immediately

// ============================================================================
// Types
// ============================================================================

type request
type response
type next
type application

type requestHandler = (request, response, next) => promise<unit>
type errorHandler = (exn, request, response, next) => promise<unit>

// ============================================================================
// Application
// ============================================================================

@module("express")
external express: unit => application = "default"

@send
external use: (application, 'a) => unit = "use"

@send
external useHandler: (application, requestHandler) => unit = "use"

@send
external useErrorHandler: (application, errorHandler) => unit = "use"

@send
external listen: (application, int, unit => unit) => unit = "listen"

// ============================================================================
// Routing
// ============================================================================

@send
external get: (application, string, requestHandler) => unit = "get"

@send
external post: (application, string, requestHandler) => unit = "post"

@send
external put: (application, string, requestHandler) => unit = "put"

@send
external patch: (application, string, requestHandler) => unit = "patch"

@send
external delete: (application, string, requestHandler) => unit = "delete"

// ============================================================================
// Request Methods
// ============================================================================

@get
external method: request => string = "method"

@get
external path: request => string = "path"

@get
external params: request => 'a = "params"

@get
external query: request => 'a = "query"

@get
external body: request => 'a = "body"

// ============================================================================
// Response Methods
// ============================================================================

@send
external status: (response, int) => response = "status"

@send
external json: (response, 'a) => response = "json"

@send
external send: (response, string) => response = "send"

@send
external setHeader: (response, string, string) => unit = "set"

// ============================================================================
// Middleware
// ============================================================================

@module("cors")
external cors: unit => 'a = "default"

@module("express")
external json: unit => 'a = "json"
