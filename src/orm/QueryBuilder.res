// Concrete QueryBuilder for Item queries
// NOT generic — explicitly typed for Item records
// This simplifies the architecture and makes query logic obvious

open Bun.sqlite

// ============================================================================
// Types
// ============================================================================

type itemRow = {
  "id": int,
  "name": string,
  "description": option<string>,
  "categoryId": int,
  "createdAt": float,
  "updatedAt": float,
}

// Query context for building queries incrementally
// We keep this simple: just the DB, SQL, and parameters
type query = {
  db: database,
  sql: string,
  params: array<'a>, // params stay generic internally, but queries are concrete
}

// ============================================================================
// SELECT Queries
// ============================================================================

// Find all items
let selectAll = (db: database): array<itemRow> => {
  let sql = "SELECT id, name, description, categoryId, createdAt, updatedAt FROM items"
  let stmt = db->prepare(sql)
  stmt->all()
}

// Find item by ID
let findById = (db: database, id: int): option<itemRow> => {
  let sql = "SELECT id, name, description, categoryId, createdAt, updatedAt FROM items WHERE id = ?"
  let stmt = db->prepare(sql)
  stmt->get(id)
}

// Find items by category ID
let findByCategory = (db: database, categoryId: int): array<itemRow> => {
  let sql = "SELECT id, name, description, categoryId, createdAt, updatedAt FROM items WHERE categoryId = ?"
  let stmt = db->prepare(sql)
  stmt->all(categoryId)
}

// Find items by name (substring search)
let findByName = (db: database, name: string): array<itemRow> => {
  let sql = "SELECT id, name, description, categoryId, createdAt, updatedAt FROM items WHERE name LIKE ?"
  let stmt = db->prepare(sql)
  let pattern = `%${name}%`
  stmt->all(pattern)
}

// Find items with pagination
let findWithPagination = (db: database, limit: int, offset: int): array<itemRow> => {
  let sql = "SELECT id, name, description, categoryId, createdAt, updatedAt FROM items LIMIT ? OFFSET ?"
  let stmt = db->prepare(sql)
  stmt->all(limit, offset)
}

// ============================================================================
// INSERT Queries
// ============================================================================

// Insert a single item, return the last inserted row ID
let insertItem = (
  db: database,
  ~name: string,
  ~description: option<string>,
  ~categoryId: int,
): result<int, string> => {
  let now = Date.now() /. 1000.0 // Unix timestamp in seconds
  let sql = "INSERT INTO items (name, description, categoryId, createdAt, updatedAt) VALUES (?, ?, ?, ?, ?)"
  let stmt = db->prepare(sql)
  let descStr = description->Option.getOr("")
  
  try {
    let result = stmt->run(name, descStr, categoryId, now, now)
    let rowId = result["lastInsertRowid"]->Bigint.toNumber->Int.fromFloat
    Ok(rowId)
  } catch {
  | _ => Error("Failed to insert item")
  }
}

// ============================================================================
// UPDATE Queries
// ============================================================================

// Update an item by ID
let updateItem = (
  db: database,
  id: int,
  ~name: string,
  ~description: option<string>,
  ~categoryId: int,
): result<int, string> => {
  let now = Date.now() /. 1000.0
  let sql = "UPDATE items SET name = ?, description = ?, categoryId = ?, updatedAt = ? WHERE id = ?"
  let stmt = db->prepare(sql)
  let descStr = description->Option.getOr("")
  
  try {
    let result = stmt->run(name, descStr, categoryId, now, id)
    Ok(result["changes"])
  } catch {
  | _ => Error("Failed to update item")
  }
}

// ============================================================================
// DELETE Queries
// ============================================================================

// Delete an item by ID
let deleteById = (db: database, id: int): result<int, string> => {
  let sql = "DELETE FROM items WHERE id = ?"
  let stmt = db->prepare(sql)
  
  try {
    let result = stmt->run(id)
    Ok(result["changes"])
  } catch {
  | _ => Error("Failed to delete item")
  }
}

// ============================================================================
// Utilities
// ============================================================================

// Check if an item exists
let exists = (db: database, id: int): bool => {
  let sql = "SELECT 1 FROM items WHERE id = ? LIMIT 1"
  let stmt = db->prepare(sql)
  stmt->get(id)->Option.isSome
}

// Count all items
let count = (db: database): int => {
  let sql = "SELECT COUNT(*) as count FROM items"
  let stmt = db->prepare(sql)
  switch stmt->get() {
  | Some(row: {"count": int}) => row["count"]
  | None => 0
  }
}
