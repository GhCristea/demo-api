// Item data access — SQL + params + mapper, nothing else
// All queries return result<_, AppError.t> — no exceptions escape
// Adding a field: update `cols` only — all queries inherit the change

let cols = "id, name, description, categoryId, createdAt, updatedAt"

let findAll = (db, _params: Schema.Items.listParams): result<array<Item.t>, AppError.t> =>
  Sqlite.all(db, `SELECT ${cols} FROM items`, [])
  ->Result.map(rows => rows->Array.map(Item.fromRow))

let findById = (db, id: int): result<Item.t, AppError.t> =>
  Sqlite.getOrErr(db, `SELECT ${cols} FROM items WHERE id = ?`, [id],
    ~err=AppError.NotFound(`Item ${Int.toString(id)} not found`), Item.fromRow)

let insert = (db, input: Schema.Items.insertRow): result<Item.t, AppError.t> =>
  Sqlite.getOrErr(db,
    `INSERT INTO items (name, description, categoryId) VALUES (?, ?, ?) RETURNING ${cols}`,
    [input.name->Obj.magic, input.description->Js.Nullable.fromOption->Obj.magic, input.categoryId->Obj.magic],
    ~err=AppError.Internal("Insert returned no row"), Item.fromRow)

let replace = (db, input: Schema.Items.replaceRow): result<Item.t, AppError.t> =>
  Sqlite.getOrErr(db,
    `UPDATE items SET name = ?, description = ?, categoryId = ?, updatedAt = unixepoch('now','subsec') WHERE id = ? RETURNING ${cols}`,
    [input.name->Obj.magic, input.description->Js.Nullable.fromOption->Obj.magic, input.categoryId->Obj.magic, input.id->Obj.magic],
    ~err=AppError.NotFound(`Item ${Int.toString(input.id)} not found`), Item.fromRow)

let patch = (db, id: int, input: Schema.Items.patchRow): result<Item.t, AppError.t> =>
  Sqlite.getOrErr(db,
    `UPDATE items SET name = COALESCE(?, name), description = COALESCE(?, description), categoryId = COALESCE(?, categoryId), updatedAt = unixepoch('now','subsec') WHERE id = ? RETURNING ${cols}`,
    [input.name->Js.Nullable.fromOption->Obj.magic, input.description->Js.Nullable.fromOption->Obj.magic, input.categoryId->Js.Nullable.fromOption->Obj.magic, id->Obj.magic],
    ~err=AppError.NotFound(`Item ${Int.toString(id)} not found`), Item.fromRow)

let delete = (db, id: int): result<unit, AppError.t> =>
  Sqlite.runOrNotFound(db, "DELETE FROM items WHERE id = ?", [id],
    ~notFound=AppError.NotFound(`Item ${Int.toString(id)} not found`))

// Bulk ops — all-or-nothing via SQLite transaction
let insertMany = (db, inputs: array<Schema.Items.insertRow>): result<array<Item.t>, AppError.t> =>
  Sqlite.inTransaction(db, () => inputs->Array.map(insert(db))->Result.all)
  ->Result.flatMap(r => r)

let replaceMany = (db, inputs: array<Schema.Items.replaceRow>): result<array<Item.t>, AppError.t> =>
  Sqlite.inTransaction(db, () => inputs->Array.map(replace(db))->Result.all)
  ->Result.flatMap(r => r)

let deleteMany = (db, ids: array<int>): result<unit, AppError.t> =>
  Sqlite.inTransaction(db, () => ids->Array.map(delete(db))->Result.all)
  ->Result.flatMap(r => r->Result.map(_ => ()))
