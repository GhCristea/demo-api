// FFI bindings for Bun.sql (bun:sqlite module)
// Bun.sql provides a high-performance SQLite interface compatible with better-sqlite3 API

// Abstract types for the database and statements
// We don't expose their internal structure; callers use these through our API
type database
type statement<'a>

// ============================================================================
// Database Initialization
// ============================================================================

@module("bun:sqlite")
@new
external open: string => database = "Database"

@send
external openWithFilename: database => string = "filename"

@send
external exec: (database, string) => database = "exec"

// ============================================================================
// Statement Preparation & Binding
// ============================================================================

@send
external prepare: (database, string) => statement<'a> = "prepare"

// Bind parameters to a prepared statement (in-place mutation)
// Bun.sql uses numeric indices (1-based) or named parameters
@send
external bind: (statement<'a>, ...array<'b>) => statement<'a> = "bind"

// ============================================================================
// Query Execution (Synchronous)
// ============================================================================

// Execute and retrieve all rows matching the query
// Parameters are passed as spread arguments: stmt->all(param1, param2, ...)
@send
external all: (statement<'a>, ...array<'b>) => array<'a> = "all"

// Execute and retrieve the first row, or None
@send
external get: (statement<'a>, ...array<'b>) => option<'a> = "get"

// Execute a mutation (INSERT, UPDATE, DELETE)
// Returns metadata: { changes: int, lastInsertRowid: bigint }
@send
external run: (statement<'a>, ...array<'b>) => {'changes': int, 'lastInsertRowid': Bigint.t} = "run"

// ============================================================================
// Transactions
// ============================================================================

// Begin a transaction
@send
external begin: database => statement<unit> = "exec"

// Commit a transaction
@send
external commit: database => statement<unit> = "exec"

// Rollback a transaction
@send
external rollback: database => statement<unit> = "exec"

// ============================================================================
// Utility
// ============================================================================

// Close the database connection
@send
external close: database => unit = "close"

// Get the last error message (if any)
@get
external lastError: database => option<string> = "lastError"
