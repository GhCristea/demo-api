// Data Transfer Objects using rescript-schema
// Replaces Zod with a fully type-safe validation layer
// rescript-schema guarantees the Output type matches the validator

open S // rescript-schema

// ============================================================================
// Create Item DTO
// ============================================================================

let createItemSchema = schema(s => {
  {
    "name": s.field("name", s.string()->min(~length=3, ())->max(~length=100, ())),
    "description": s.field("description", s.option(s.string())),
    "categoryId": s.field("categoryId", s.int()),
  }
})

type createItemInput = S.Output.t<typeof createItemSchema>

// ============================================================================
// Update Item DTO
// ============================================================================

let updateItemSchema = schema(s => {
  {
    "name": s.field("name", s.option(s.string()->min(~length=3, ())->max(~length=100, ()))),
    "description": s.field("description", s.option(s.string())),
    "categoryId": s.field("categoryId", s.option(s.int())),
  }
})

type updateItemInput = S.Output.t<typeof updateItemSchema>

// ============================================================================
// Response DTO (Item)
// ============================================================================

let itemResponseSchema = schema(s => {
  {
    "id": s.field("id", s.int()),
    "name": s.field("name", s.string()),
    "description": s.field("description", s.option(s.string())),
    "categoryId": s.field("categoryId", s.int()),
    "createdAt": s.field("createdAt", s.float()),
    "updatedAt": s.field("updatedAt", s.float()),
  }
})

type itemResponse = S.Output.t<typeof itemResponseSchema>

// ============================================================================
// Validation Helpers
// ============================================================================

// Parse and validate JSON from request body
let validateCreateItem = (json: 'a): result<createItemInput, string> => {
  try {
    Ok(S.parseAsync(createItemSchema, json)->Promise.getResult)
  } catch {
  | _ => Error("Invalid request body")
  }
}

let validateUpdateItem = (json: 'a): result<updateItemInput, string> => {
  try {
    Ok(S.parseAsync(updateItemSchema, json)->Promise.getResult)
  } catch {
  | _ => Error("Invalid request body")
  }
}

// Convert Item entity to response DTO
let toResponse = (item: Item.item): itemResponse => {
  {
    "id": item.id,
    "name": item.name,
    "description": item.description,
    "categoryId": item.categoryId,
    "createdAt": item.createdAt,
    "updatedAt": item.updatedAt,
  }
}
