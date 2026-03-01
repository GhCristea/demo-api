// Item data access — pure functions, db is a parameter
// Bulk ops are wrapped in a single transaction: all-or-nothing
// findAll supports optional search (matches category name) and limit

type db = Bun.Sqlite.db

let rowToItem = (row: Schema.Items.row): Item.t => Item.fromRow(row)

// ─── Helpers ────────────────────────────────────────────────────────────────────

let inTransaction = (db: db, f: unit => result<'a, AppError.t>): result<'a, AppError.t> => {
  try {
    db->Bun.Sqlite.exec("BEGIN")
    switch f() {
    | Ok(_) as ok =>
      db->Bun.Sqlite.exec("COMMIT")
      ok
    | Error(_) as err =>
      db->Bun.Sqlite.exec("ROLLBACK")
      err
    }
  } catch {
  | Js.Exn.Error(e) =>
    db->Bun.Sqlite.exec("ROLLBACK")
    Error(AppError.Internal(Js.Exn.message(e)->Option.getOr("Transaction error")))
  }
}

let selectCols = "i.id, i.name, i.description, i.categoryId, i.createdAt, i.updatedAt"

// ─── Queries ───────────────────────────────────────────────────────────────────

// Search matches category name via JOIN
// Both params are optional — omitting them returns all items with no limit
let findAll = (db: db, params: Schema.Items.listParams): result<array<Item.t>, AppError.t> =>
  try {
    let (sql, args) = switch (params.search, params.limit) {
    | (Some(term), Some(lim)) => (
        `SELECT ${selectCols} FROM items i
         JOIN categories c ON i.categoryId = c.id
         WHERE c.name LIKE ?
         LIMIT ?`,
        [Obj.magic("%" ++ term ++ "%"), Obj.magic(lim)],
      )
    | (Some(term), None) => (
        `SELECT ${selectCols} FROM items i
         JOIN categories c ON i.categoryId = c.id
         WHERE c.name LIKE ?`,
        [Obj.magic("%" ++ term ++ "%")],
      )
    | (None, Some(lim)) => (
        `SELECT ${selectCols} FROM items i LIMIT ?`,
        [Obj.magic(lim)],
      )
    | (None, None) => (
        `SELECT ${selectCols} FROM items i`,
        [],
      )
    }
    let rows: array<Schema.Items.row> =
      db->Bun.Sqlite.prepare(sql)->Bun.Sqlite.all(args)
    Ok(rows->Js.Array2.map(rowToItem))
  } catch {
  | Js.Exn.Error(e) => Error(AppError.Internal(Js.Exn.message(e)->Option.getOr("DB error")))
  }

let findById = (db: db, id: int): result<Item.t, AppError.t> =>
  try {
    db
    ->Bun.Sqlite.prepare(
      `SELECT ${selectCols} FROM items i WHERE i.id = ?`,
    )
    ->Bun.Sqlite.get([id])
    ->Js.Nullable.toOption
    ->Option.map(rowToItem)
    ->Result.fromOption(AppError.NotFound(`Item ${Int.toString(id)} not found`))
  } catch {
  | Js.Exn.Error(e) => Error(AppError.Internal(Js.Exn.message(e)->Option.getOr("DB error")))
  }

// ─── Mutations ─────────────────────────────────────────────────────────────────

let insertSql = `INSERT INTO items (name, description, categoryId)
  VALUES (?, ?, ?)
  RETURNING id, name, description, categoryId, createdAt, updatedAt`

let insert = (db: db, input: Schema.Items.insertRow): result<Item.t, AppError.t> =>
  try {
    let desc = input.description->Option.getOr("")
    db
    ->Bun.Sqlite.prepare(insertSql)
    ->Bun.Sqlite.get([input.name, desc, input.categoryId])
    ->Js.Nullable.toOption
    ->Option.map(rowToItem)
    ->Result.fromOption(AppError.Internal("Insert returned no row"))
  } catch {
  | Js.Exn.Error(e) => Error(AppError.Internal(Js.Exn.message(e)->Option.getOr("DB error")))
  }

// All-or-nothing: if any insert fails the whole batch is rolled back
let insertMany = (db: db, inputs: array<Schema.Items.insertRow>): result<array<Item.t>, AppError.t> =>
  inTransaction(db, () => {
    let stmt = db->Bun.Sqlite.prepare(insertSql)
    let results: array<Item.t> = []
    let err: ref<option<AppError.t>> = ref(None)
    inputs->Js.Array2.forEach(input => {
      if err.contents->Option.isNone {
        let desc = input.description->Option.getOr("")
        switch stmt->Bun.Sqlite.get([input.name, desc, input.categoryId])->Js.Nullable.toOption {
        | Some(row) => results->Js.Array2.push(rowToItem(row))->ignore
        | None => err := Some(AppError.Internal("Insert returned no row"))
        }
      }
    })
    switch err.contents {
    | Some(e) => Error(e)
    | None => Ok(results)
    }
  })

// PUT: full replace — description is set to NULL if not provided
let replaceSql = `UPDATE items
  SET name = ?, description = ?, categoryId = ?, updatedAt = unixepoch('now','subsec')
  WHERE id = ?
  RETURNING id, name, description, categoryId, createdAt, updatedAt`

let replace = (db: db, input: Schema.Items.replaceRow): result<Item.t, AppError.t> =>
  try {
    let desc = input.description->Option.getOr("")
    db
    ->Bun.Sqlite.prepare(replaceSql)
    ->Bun.Sqlite.get([input.name, desc, input.categoryId, input.id])
    ->Js.Nullable.toOption
    ->Option.map(rowToItem)
    ->Result.fromOption(AppError.NotFound(`Item ${Int.toString(input.id)} not found`))
  } catch {
  | Js.Exn.Error(e) => Error(AppError.Internal(Js.Exn.message(e)->Option.getOr("DB error")))
  }

// Bulk PUT — all-or-nothing transaction
let replaceMany = (db: db, inputs: array<Schema.Items.replaceRow>): result<array<Item.t>, AppError.t> =>
  inTransaction(db, () => {
    let stmt = db->Bun.Sqlite.prepare(replaceSql)
    let results: array<Item.t> = []
    let err: ref<option<AppError.t>> = ref(None)
    inputs->Js.Array2.forEach(input => {
      if err.contents->Option.isNone {
        let desc = input.description->Option.getOr("")
        switch stmt->Bun.Sqlite.get([input.name, desc, input.categoryId, input.id])->Js.Nullable.toOption {
        | Some(row) => results->Js.Array2.push(rowToItem(row))->ignore
        | None => err := Some(AppError.NotFound(`Item ${Int.toString(input.id)} not found`))
        }
      }
    })
    switch err.contents {
    | Some(e) => Error(e)
    | None => Ok(results)
    }
  })

let delete = (db: db, id: int): result<unit, AppError.t> =>
  try {
    let meta =
      db
      ->Bun.Sqlite.prepare("DELETE FROM items WHERE id = ?")
      ->Bun.Sqlite.run([id])
    if meta["changes"] > 0 {
      Ok(())
    } else {
      Error(AppError.NotFound(`Item ${Int.toString(id)} not found`))
    }
  } catch {
  | Js.Exn.Error(e) => Error(AppError.Internal(Js.Exn.message(e)->Option.getOr("DB error")))
  }

// Bulk DELETE — all-or-nothing transaction
let deleteMany = (db: db, ids: array<int>): result<unit, AppError.t> =>
  inTransaction(db, () => {
    let stmt = db->Bun.Sqlite.prepare("DELETE FROM items WHERE id = ?")
    let err: ref<option<AppError.t>> = ref(None)
    ids->Js.Array2.forEach(id => {
      if err.contents->Option.isNone {
        let meta = stmt->Bun.Sqlite.run([id])
        if meta["changes"] === 0 {
          err := Some(AppError.NotFound(`Item ${Int.toString(id)} not found`))
        }
      }
    })
    switch err.contents {
    | Some(e) => Error(e)
    | None => Ok(())
    }
  })
