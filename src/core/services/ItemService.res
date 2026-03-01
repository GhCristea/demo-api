// ItemService: Business logic layer
// All queries go through QueryBuilder
// All errors are handled via Result<T, AppError>
// No exceptions or null checks

open Bun.sqlite

// Database instance (injected from AppDataSource)
let mutable db: option<database> = None

let setDatabase = (database: database) => {
  db := Some(database)
}

let getDb = (): result<database, AppError.t> => {
  switch db.contents {
  | Some(d) => Ok(d)
  | None => Error(AppError.internal("Database not initialized"))
  }
}

// ============================================================================
// Query Operations
// ============================================================================

let getAll = (): result<array<Item.item>, AppError.t> => {
  getDb()->Result.flatMap(db => {
    try {
      let rows = QueryBuilder.selectAll(db)
      Ok(rows->Array.map(Item.fromRow))
    } catch {
    | _ => Error(AppError.internal("Failed to fetch items"))
    }
  })
}

let getOne = (id: int): result<Item.item, AppError.t> => {
  getDb()->Result.flatMap(db => {
    try {
      switch QueryBuilder.findById(db, id) {
      | Some(row) => Ok(Item.fromRow(row))
      | None => Error(AppError.itemNotFound())
      }
    } catch {
    | _ => Error(AppError.internal("Failed to fetch item"))
    }
  })
}

let getByCategory = (categoryId: int): result<array<Item.item>, AppError.t> => {
  getDb()->Result.flatMap(db => {
    try {
      let rows = QueryBuilder.findByCategory(db, categoryId)
      Ok(rows->Array.map(Item.fromRow))
    } catch {
    | _ => Error(AppError.internal("Failed to fetch items by category"))
    }
  })
}

let search = (name: string): result<array<Item.item>, AppError.t> => {
  getDb()->Result.flatMap(db => {
    try {
      let rows = QueryBuilder.findByName(db, name)
      Ok(rows->Array.map(Item.fromRow))
    } catch {
    | _ => Error(AppError.internal("Failed to search items"))
    }
  })
}

// ============================================================================
// Mutation Operations
// ============================================================================

let create = (
  input: ItemDto.createItemInput,
): result<Item.item, AppError.t> => {
  getDb()->Result.flatMap(db => {
    try {
      switch QueryBuilder.insertItem(
        db,
        ~name=input["name"],
        ~description=input["description"],
        ~categoryId=input["categoryId"],
      ) {
      | Ok(id) =>
        // Fetch and return the created item
        switch QueryBuilder.findById(db, id) {
        | Some(row) => Ok(Item.fromRow(row))
        | None => Error(AppError.internal("Failed to retrieve created item"))
        }
      | Error(msg) => Error(AppError.internal(msg))
      }
    } catch {
    | _ => Error(AppError.internal("Failed to create item"))
    }
  })
}

let update = (
  id: int,
  input: ItemDto.updateItemInput,
): result<Item.item, AppError.t> => {
  getDb()->Result.flatMap(db => {
    try {
      // Check if item exists first
      switch QueryBuilder.findById(db, id) {
      | None => Error(AppError.itemNotFound())
      | Some(existing) =>
        // Use provided values or fall back to existing
        let name = input["name"]->Option.getOr(existing["name"])
        let description = input["description"]->Option.or_(existing["description"])
        let categoryId = input["categoryId"]->Option.getOr(existing["categoryId"])

        switch QueryBuilder.updateItem(db, id, ~name, ~description, ~categoryId) {
        | Ok(_) =>
          // Fetch and return the updated item
          switch QueryBuilder.findById(db, id) {
          | Some(row) => Ok(Item.fromRow(row))
          | None => Error(AppError.internal("Failed to retrieve updated item"))
          }
        | Error(msg) => Error(AppError.internal(msg))
        }
      }
    } catch {
    | _ => Error(AppError.internal("Failed to update item"))
    }
  })
}

let delete = (id: int): result<unit, AppError.t> => {
  getDb()->Result.flatMap(db => {
    try {
      switch QueryBuilder.deleteById(db, id) {
      | Ok(changes) =>
        if changes > 0 {
          Ok()
        } else {
          Error(AppError.itemNotFound())
        }
      | Error(msg) => Error(AppError.internal(msg))
      }
    } catch {
    | _ => Error(AppError.internal("Failed to delete item"))
    }
  })
}
