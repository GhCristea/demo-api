// Type-safe error hierarchy using ReScript variants
// Replaces the AppError class pattern with exhaustive pattern matching
// Compiler forces all error cases to be handled

type t =
  | NotFound(string) // resource type (e.g., "Item", "Category")
  | ValidationError(array<string>) // array of validation messages
  | Conflict(string) // resource already exists
  | Unauthorized(string) // authentication failed
  | Forbidden(string) // permission denied
  | Internal(string) // unrecoverable server error

// ============================================================================
// Error to HTTP Status Code
// ============================================================================

let statusCode = (err: t): int => {
  switch err {
  | NotFound(_) => 404
  | ValidationError(_) => 400
  | Conflict(_) => 409
  | Unauthorized(_) => 401
  | Forbidden(_) => 403
  | Internal(_) => 500
  }
}

// ============================================================================
// Error to Message
// ============================================================================

let message = (err: t): string => {
  switch err {
  | NotFound(resource) => `${resource} not found`
  | ValidationError(messages) => `Validation failed: ${messages->Array.join(", ")}`
  | Conflict(msg) => `Conflict: ${msg}`
  | Unauthorized(msg) => `Unauthorized: ${msg}`
  | Forbidden(msg) => `Forbidden: ${msg}`
  | Internal(msg) => `Internal Server Error: ${msg}`
  }
}

// ============================================================================
// JSON Error Response
// ============================================================================

type errorResponse = {
  "status": int,
  "message": string,
  "errors": option<array<string>>,
}

let toResponse = (err: t): errorResponse => {
  switch err {
  | NotFound(resource) => {
      "status": 404,
      "message": `${resource} not found`,
      "errors": None,
    }
  | ValidationError(messages) => {
      "status": 400,
      "message": "Validation failed",
      "errors": Some(messages),
    }
  | Conflict(msg) => {
      "status": 409,
      "message": msg,
      "errors": None,
    }
  | Unauthorized(msg) => {
      "status": 401,
      "message": msg,
      "errors": None,
    }
  | Forbidden(msg) => {
      "status": 403,
      "message": msg,
      "errors": None,
    }
  | Internal(msg) => {
      "status": 500,
      "message": msg,
      "errors": None,
    }
  }
}

// ============================================================================
// Common Error Constructors
// ============================================================================

let itemNotFound = () => NotFound("Item")
let categoryNotFound = () => NotFound("Category")
let validationFailed = (messages: array<string>) => ValidationError(messages)
let resourceConflict = (msg: string) => Conflict(msg)
let unauthorized = (msg: string) => Unauthorized(msg)
let forbidden = (msg: string) => Forbidden(msg)
let internal = (msg: string) => Internal(msg)
