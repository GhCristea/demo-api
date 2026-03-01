// Item data access — pure functions, db is a parameter
// All queries return result types — no exceptions escape this module
// Adding a new resource follows the same pattern in a new Repo file

type db = Bun.Sqlite.db

type row = {
  "id": int,
  "name": string,
  "description": Js.Nullable.t<string>,
  "createdAt": float,
  "updatedAt": float,
}

let findAll = (db: db): result<array<Item.t>, AppError.t> =>
  try {
    let rows: array<row> =
      db->Bun.Sqlite.prepare("SELECT id, name, description, createdAt, updatedAt FROM items")
      ->Bun.Sqlite.all([])
    Ok(rows->Js.Array2.map(Item.fromRow))
  } catch {
  | Js.Exn.Error(e) => Error(AppError.Internal(Js.Exn.message(e)->Option.getOr("DB error")))
  }

let findById = (db: db, id: int): result<Item.t, AppError.t> =>
  try {
    db->Bun.Sqlite.prepare("SELECT id, name, description, createdAt, updatedAt FROM items WHERE id = ?")
    ->Bun.Sqlite.get([id])
    ->Js.Nullable.toOption
    ->Option.map(Item.fromRow)
    ->Result.fromOption(AppError.NotFound(`Item ${Int.toString(id)} not found`))
  } catch {
  | Js.Exn.Error(e) => Error(AppError.Internal(Js.Exn.message(e)->Option.getOr("DB error")))
  }

let insert = (db: db, input: Schemas.createInput): result<Item.t, AppError.t> =>
  try {
    let desc = input.description->Option.getOr("")
    let meta =
      db->Bun.Sqlite.prepare("INSERT INTO items (name, description) VALUES (?, ?) RETURNING id, name, description, createdAt, updatedAt")
      ->Bun.Sqlite.get([input.name, desc])
    switch meta->Js.Nullable.toOption {
    | Some(row) => Ok(Item.fromRow(row))
    | None => Error(AppError.Internal("Insert returned no row"))
    }
  } catch {
  | Js.Exn.Error(e) => Error(AppError.Internal(Js.Exn.message(e)->Option.getOr("DB error")))
  }

let patch = (db: db, id: int, input: Schemas.updateInput): result<Item.t, AppError.t> =>
  try {
    // Only set fields that are Some — COALESCE keeps existing value otherwise
    let row =
      db->Bun.Sqlite.prepare(
        "UPDATE items SET name = COALESCE(?, name), description = COALESCE(?, description), updatedAt = unixepoch('now', 'subsec') WHERE id = ? RETURNING id, name, description, createdAt, updatedAt",
      )
      ->Bun.Sqlite.get([
        input.name->Option.getOr(""),
        input.description->Option.getOr(""),
        id,
      ])
    switch row->Js.Nullable.toOption {
    | Some(r) => Ok(Item.fromRow(r))
    | None => Error(AppError.NotFound(`Item ${Int.toString(id)} not found`))
    }
  } catch {
  | Js.Exn.Error(e) => Error(AppError.Internal(Js.Exn.message(e)->Option.getOr("DB error")))
  }

let delete = (db: db, id: int): result<unit, AppError.t> =>
  try {
    let meta =
      db->Bun.Sqlite.prepare("DELETE FROM items WHERE id = ?")
      ->Bun.Sqlite.run([id])
    if meta["changes"] > 0 {
      Ok(())
    } else {
      Error(AppError.NotFound(`Item ${Int.toString(id)} not found`))
    }
  } catch {
  | Js.Exn.Error(e) => Error(AppError.Internal(Js.Exn.message(e)->Option.getOr("DB error")))
  }
