// Validation schemas — single source of truth for all API inputs
// Uses rescript-schema: schema IS the type (S.Output.t)
// No manual type duplication

open S

let createItem = schema(s => {
  name: s.field("name", s.string->String.min(1)),
  description: s.field("description", s.option(s.string)),
})

let updateItem = schema(s => {
  name: s.field("name", s.option(s.string->String.min(1))),
  description: s.field("description", s.option(s.string)),
})

type createInput = S.Output.t<typeof createItem>
type updateInput = S.Output.t<typeof updateItem>

// Parse helpers — boundary between untyped JSON and typed domain
let parseCreate = (json: Js.Json.t): result<createInput, AppError.t> =>
  switch createItem->S.parseOrThrow(json) {
  | input => Ok(input)
  | exception S.Error(e) => Error(AppError.ValidationError([S.Error.message(e)]))
  }

let parseUpdate = (json: Js.Json.t): result<updateInput, AppError.t> =>
  switch updateItem->S.parseOrThrow(json) {
  | input => Ok(input)
  | exception S.Error(e) => Error(AppError.ValidationError([S.Error.message(e)]))
  }
