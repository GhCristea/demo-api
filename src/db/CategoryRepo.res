// Category data access — mirrors ItemRepo pattern
// Adding a field: update `cols` only

let cols = "id, name, description, createdAt, updatedAt"

let findAll = (db): result<array<Category.t>, AppError.t> =>
  Sqlite.all(db, `SELECT ${cols} FROM categories`, [])
  ->Result.map(rows => rows->Array.map(Category.fromRow))

let findById = (db, id: int): result<Category.t, AppError.t> =>
  Sqlite.getOrErr(db, `SELECT ${cols} FROM categories WHERE id = ?`, [id],
    ~err=AppError.NotFound(`Category ${Int.toString(id)} not found`), Category.fromRow)

let findByItemId = (db, itemId: int): result<Category.t, AppError.t> =>
  Sqlite.getOrErr(db,
    `SELECT c.${cols} FROM categories c
     JOIN items i ON i.categoryId = c.id
     WHERE i.id = ?`, [itemId],
    ~err=AppError.NotFound(`Category for item ${Int.toString(itemId)} not found`),
    Category.fromRow)

let insert = (db, input: Schema.Categories.insertRow): result<Category.t, AppError.t> =>
  Sqlite.getOrErr(db,
    `INSERT INTO categories (name, description) VALUES (?, ?) RETURNING ${cols}`,
    [input.name->Obj.magic, input.description->Js.Nullable.fromOption->Obj.magic],
    ~err=AppError.Internal("Insert returned no row"), Category.fromRow)

let replace = (db, input: Schema.Categories.replaceRow): result<Category.t, AppError.t> =>
  Sqlite.getOrErr(db,
    `UPDATE categories SET name = ?, description = ?, updatedAt = unixepoch('now','subsec') WHERE id = ? RETURNING ${cols}`,
    [input.name->Obj.magic, input.description->Js.Nullable.fromOption->Obj.magic, input.id->Obj.magic],
    ~err=AppError.NotFound(`Category ${Int.toString(input.id)} not found`), Category.fromRow)

let patch = (db, id: int, input: Schema.Categories.patchRow): result<Category.t, AppError.t> =>
  Sqlite.getOrErr(db,
    `UPDATE categories SET name = COALESCE(?, name), description = COALESCE(?, description), updatedAt = unixepoch('now','subsec') WHERE id = ? RETURNING ${cols}`,
    [input.name->Js.Nullable.fromOption->Obj.magic, input.description->Js.Nullable.fromOption->Obj.magic, id->Obj.magic],
    ~err=AppError.NotFound(`Category ${Int.toString(id)} not found`), Category.fromRow)

let delete = (db, id: int): result<unit, AppError.t> =>
  Sqlite.runOrNotFound(db, "DELETE FROM categories WHERE id = ?", [id],
    ~notFound=AppError.NotFound(`Category ${Int.toString(id)} not found`))

let insertMany = (db, inputs: array<Schema.Categories.insertRow>): result<array<Category.t>, AppError.t> =>
  Sqlite.inTransaction(db, () => inputs->Array.map(insert(db))->Result.all)
  ->Result.flatMap(r => r)

let replaceMany = (db, inputs: array<Schema.Categories.replaceRow>): result<array<Category.t>, AppError.t> =>
  Sqlite.inTransaction(db, () => inputs->Array.map(replace(db))->Result.all)
  ->Result.flatMap(r => r)

let deleteMany = (db, ids: array<int>): result<unit, AppError.t> =>
  Sqlite.inTransaction(db, () => ids->Array.map(delete(db))->Result.all)
  ->Result.flatMap(r => r->Result.map(_ => ()))
