// AppDataSource: Database initialization and lifecycle management
// Handles connection pooling, schema creation, and service injection

open Bun.sqlite

let mutable isInitialized = false

type dataSource = {
  db: database,
}

let mutable dataSource: option<dataSource> = None

// ============================================================================
// Initialization
// ============================================================================

let initialize = async (): promise<result<dataSource, string>> => {
  try {
    if isInitialized {
      Error("DataSource already initialized")->Promise.resolve
    } else {
      // Open database (creates file if it doesn't exist)
      let db = Bun.sqlite.open("./data.db")

      // Enable foreign keys (off by default in SQLite)
      let stmt = db->prepare("PRAGMA foreign_keys = ON")
      stmt->run()

      // Create schema
      try {
        db->exec(Item.createTableSQL)
        db->exec(Item.createCategoryIndexSQL)
        // Add more schema as needed: Category, Order, etc.

        // Inject DB into service layer
        ItemService.setDatabase(db)

        isInitialized = true
        dataSource := Some({db})

        Ok({db})->Promise.resolve
      } catch {
      | _ =>
        db->close()
        Error("Failed to create database schema")->Promise.resolve
      }
    }
  } catch {
  | _ => Error("Failed to open database")->Promise.resolve
  }
}

// ============================================================================
// Cleanup
// ============================================================================

let destroy = (): unit => {
  switch dataSource.contents {
  | Some({db}) =>
    try {
      db->close()
      dataSource := None
      isInitialized = false
    } catch {
    | _ => ()
    }
  | None => ()
  }
}

// ============================================================================
// Access
// ============================================================================

let getInstance = (): option<dataSource> => dataSource.contents

let getDatabase = (): option<database> => {
  switch dataSource.contents {
  | Some(ds) => Some(ds.db)
  | None => None
  }
}
