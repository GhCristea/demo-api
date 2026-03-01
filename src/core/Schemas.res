// Validation schemas — single source of truth for all API inputs
// Uses rescript-schema: schema IS the type (S.Output.t)
// Polymorphic POST body: S.union handles both single object and array

open S

// ─── Item inputs ─────────────────────────────────────────────────────────────────

// POST /rest/items single object body
let createItem = schema(s => ({
  name:        s.field("name",        s.string->String.min(1)),
  description: s.field("description", s.option(s.string)),
  categoryId:  s.field("categoryId",  s.int),
}: Schema.Items.insertRow))

// POST /rest/items array body
let createItems = schema(s => s.array(createItem))

// Polymorphic POST body — single object OR array
// Returns array in both cases for uniform handling downstream
let createItemBody = schema(s =>
  s.union([
    schema(s => [s.matches(createItem)]),
    schema(s => s.matches(createItems)),
  ])
)

// PUT /rest/items/:id
let replaceItem = schema(s => ({
  name:        s.field("name",        s.string->String.min(1)),
  description: s.field("description", s.option(s.string)),
  categoryId:  s.field("categoryId",  s.int),
}: Schema.Items.insertRow))

// PUT /rest/items bulk — each item must include its id
let replaceItemWithId = schema(s => ({
  id:          s.field("id",          s.int),
  name:        s.field("name",        s.string->String.min(1)),
  description: s.field("description", s.option(s.string)),
  categoryId:  s.field("categoryId",  s.int),
}: Schema.Items.replaceRow))

let replaceItems = schema(s => s.array(replaceItemWithId))

// DELETE /rest/items bulk body: [{id}, {id}]
let deleteItemsBody = schema(s =>
  s.array(schema(s => s.field("id", s.int)))
)

// ─── Parse helpers ──────────────────────────────────────────────────────────────

let parse = (schema, json): result<'a, AppError.t> =>
  switch schema->S.parseOrThrow(json) {
  | v => Ok(v)
  | exception S.Error(e) => Error(AppError.ValidationError([S.Error.message(e)]))
  }

let parseCreateBody   = (json: Js.Json.t) => parse(createItemBody,    json)
let parseReplace      = (json: Js.Json.t) => parse(replaceItem,        json)
let parseReplaceMany  = (json: Js.Json.t) => parse(replaceItems,       json)
let parseDeleteMany   = (json: Js.Json.t) => parse(deleteItemsBody,    json)
