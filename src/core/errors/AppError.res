// Minimal error handling
// Errors are represented as variants, not exceptions
// Forces explicit error handling via pattern matching

type t =
  | NotFound(string)
  | ValidationError(array<string>)
  | Conflict(string)
  | Internal(string)

// Map error to HTTP status code
let toStatus = (error: t): int =>
  switch error {
  | NotFound(_) => 404
  | ValidationError(_) => 400
  | Conflict(_) => 409
  | Internal(_) => 500
  }

// Map error to response message
let toMessage = (error: t): string =>
  switch error {
  | NotFound(msg) => msg
  | ValidationError(errors) => errors->Js.Array2.join(", ")
  | Conflict(msg) => msg
  | Internal(msg) => msg
  }

// Convert error to JSON response
let toResponse = (error: t): BunServer.response => {
  let status = toStatus(error)
  let message = toMessage(error)
  BunServer.json(
    ~status,
    Js.Json.object_(Js.Dict.fromArray([|
      ("error", Js.Json.string(message)),
      ("status", Js.Json.number(Int.toFloat(status))),
    |]))
  )
}
