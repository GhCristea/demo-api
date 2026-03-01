// Category business logic — mirrors ItemService pattern

type repo = {
  findAll:      unit => result<array<Category.t>, AppError.t>,
  findById:     int => result<Category.t, AppError.t>,
  findByItemId: int => result<Category.t, AppError.t>,
  insert:       Schema.Categories.insertRow => result<Category.t, AppError.t>,
  insertMany:   array<Schema.Categories.insertRow> => result<array<Category.t>, AppError.t>,
  replace:      Schema.Categories.replaceRow => result<Category.t, AppError.t>,
  replaceMany:  array<Schema.Categories.replaceRow> => result<array<Category.t>, AppError.t>,
  patch:        (int, Schema.Categories.patchRow) => result<Category.t, AppError.t>,
  delete:       int => result<unit, AppError.t>,
  deleteMany:   array<int> => result<unit, AppError.t>,
}

type t = repo

let make = (repo: repo): t => repo

let fromDb = (db: Bun.Sqlite.db): t =>
  make({
    findAll:      () => CategoryRepo.findAll(db),
    findById:     id     => CategoryRepo.findById(db, id),
    findByItemId: itemId => CategoryRepo.findByItemId(db, itemId),
    insert:       input  => CategoryRepo.insert(db, input),
    insertMany:   inputs => CategoryRepo.insertMany(db, inputs),
    replace:      input  => CategoryRepo.replace(db, input),
    replaceMany:  inputs => CategoryRepo.replaceMany(db, inputs),
    patch:        (id, input) => CategoryRepo.patch(db, id, input),
    delete:       id  => CategoryRepo.delete(db, id),
    deleteMany:   ids => CategoryRepo.deleteMany(db, ids),
  })

let mock = (): t => {
  let category: Category.t = {
    id: 1, name: "Mock Category", description: None,
    createdAt: 0.0, updatedAt: 0.0,
  }
  make({
    findAll:      () => Ok([category]),
    findById:     _ => Ok(category),
    findByItemId: _ => Ok(category),
    insert:       _ => Ok(category),
    insertMany:   inputs => Ok(inputs->Array.map(_ => category)),
    replace:      _ => Ok(category),
    replaceMany:  inputs => Ok(inputs->Array.map(_ => category)),
    patch:        (_, _) => Ok(category),
    delete:       _ => Ok(()),
    deleteMany:   _ => Ok(()),
  })
}
