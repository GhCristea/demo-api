// Centralized validation schemas
// Single source of truth for API input validation
// Replaces scattered TypeScript validation logic

open RescriptSchema

// ========================================================================
// Item Schemas
// ========================================================================

let itemCreateSchema = object(o => 
  o
  ->field("name", string(~min=1, ()))
  ->field("description", string()->optional)
)

let itemUpdateSchema = object(o =>
  o
  ->field("name", string(~min=1, ())->optional)
  ->field("description", string()->optional)
)

// ========================================================================
// Parse & Validate Helpers
// ========================================================================

// Parse JSON string and validate against schema
let parseCreateInput = (json: string): result<Item.createInput, array<string>> => {
  try {
    let parsed = Js.Json.parseExn(json)
    itemCreateSchema->parseWith(parsed, json)
  } catch {
  | _ => Error(["Invalid JSON"])
  }
}

let parseUpdateInput = (json: string): result<Item.updateInput, array<string>> => {
  try {
    let parsed = Js.Json.parseExn(json)
    itemUpdateSchema->parseWith(parsed, json)
  } catch {
  | _ => Error(["Invalid JSON"])
  }
}

// Helper to format validation errors
let formatErrors = (errors: array<string>): string => {
  errors->Js.Array2.join(", ")
}
