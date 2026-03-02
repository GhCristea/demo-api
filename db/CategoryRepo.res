// Category data access — pure functions, db is a parameter
// Currently exposes findAll and findByItemId (used by GET /items/:id/categories)

type db = Bun.Sqlite.db

let rowToCategory = (row: Schema.Categories.row): Category.t =>
  Category.fromRow(row)

let findAll = (db: db): result<array<Category.t>, AppError.t> =>
  try {
    let rows: array<Schema.Categories.row> =
      db
      ->Bun.Sqlite.prepare("SELECT id, name, description, createdAt, updatedAt FROM categories")
      ->Bun.Sqlite.all([])
    Ok(rows->Js.Array2.map(rowToCategory))
  } catch {
  | Js.Exn.Error(e) => Error(AppError.Internal(Js.Exn.message(e)->Option.getOr("DB error")))
  }

// Returns the single category for a given item id
// Used by GET /rest/items/:id/categories
let findByItemId = (db: db, itemId: int): result<Category.t, AppError.t> =>
  try {
    db
    ->Bun.Sqlite.prepare(
      `SELECT c.id, c.name, c.description, c.createdAt, c.updatedAt
       FROM categories c
       JOIN items i ON i.categoryId = c.id
       WHERE i.id = ?`,
    )
    ->Bun.Sqlite.get([itemId])
    ->Js.Nullable.toOption
    ->Option.map(rowToCategory)
    ->Result.fromOption(AppError.NotFound(`No category for item ${Int.toString(itemId)}`))
  } catch {
  | Js.Exn.Error(e) => Error(AppError.Internal(Js.Exn.message(e)->Option.getOr("DB error")))
  }
