// Application error variants
// Errors are data — no exceptions in business logic
// Each variant maps to an HTTP status code

type t =
  | BadRequest(string)
  | NotFound(string)
  | Conflict(string)
  | ValidationError(array<string>)
  | Internal(string)

let toStatus = (e: t): int =>
  switch e {
  | BadRequest(_) => 400
  | ValidationError(_) => 400
  | NotFound(_) => 404
  | Conflict(_) => 409
  | Internal(_) => 500
  }

let toMessage = (e: t): string =>
  switch e {
  | BadRequest(msg) | NotFound(msg) | Conflict(msg) | Internal(msg) => msg
  | ValidationError(errs) => errs->Js.Array2.joinWith(", ")
  }

let toResponse = (result: result<Js.Json.t, t>): Bun.response =>
  switch result {
  | Ok(json) => Bun.jsonResponse(json)
  | Error(e) =>
    let status = toStatus(e)
    Bun.jsonResponse(
      ~status,
      Js.Json.object_(
        Js.Dict.fromArray([
          ("error", Js.Json.string(toMessage(e))),
          ("status", Js.Json.number(Int.toFloat(status))),
        ])
      )
    )
  }
