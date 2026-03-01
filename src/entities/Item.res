// Domain entity: Item
// This represents the core business model

open Bun.sqlite

type item = {
  id: int,
  name: string,
  description: option<string>,
  categoryId: int,
  createdAt: float, // Unix timestamp
  updatedAt: float,
}

// Convert from database row to domain type
// QueryBuilder returns itemRow (matches DB structure)
// This function bridges the two
let fromRow = (row: QueryBuilder.itemRow): item => {
  id: row["id"],
  name: row["name"],
  description: row["description"],
  categoryId: row["categoryId"],
  createdAt: row["createdAt"],
  updatedAt: row["updatedAt"],
}

// ============================================================================
// Database Schema
// ============================================================================

// The SQL to initialize the items table
// This should be called during AppDataSource.initialize()
let createTableSQL = `
CREATE TABLE IF NOT EXISTS items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  description TEXT,
  categoryId INTEGER NOT NULL,
  createdAt REAL NOT NULL,
  updatedAt REAL NOT NULL,
  FOREIGN KEY (categoryId) REFERENCES categories(id) ON DELETE CASCADE
)
`

// Create an index on categoryId for faster lookups
let createCategoryIndexSQL = `
CREATE INDEX IF NOT EXISTS idx_items_categoryId ON items(categoryId)
`
