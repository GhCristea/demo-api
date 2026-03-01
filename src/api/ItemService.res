// Item business logic
// DI: deps record holds all data-access functions
// Swap repo for a mock record in tests — no framework needed

type repo = {
  findAll:     Schema.Items.listParams => result<array<Item.t>, AppError.t>,
  findById:    int => result<Item.t, AppError.t>,
  insert:      Schema.Items.insertRow => result<Item.t, AppError.t>,
  insertMany:  array<Schema.Items.insertRow> => result<array<Item.t>, AppError.t>,
  replace:     Schema.Items.replaceRow => result<Item.t, AppError.t>,
  replaceMany: array<Schema.Items.replaceRow> => result<array<Item.t>, AppError.t>,
  patch:       (int, Schema.Items.patchRow) => result<Item.t, AppError.t>,
  delete:      int => result<unit, AppError.t>,
  deleteMany:  array<int> => result<unit, AppError.t>,
}

type t = repo

let make = (repo: repo): t => repo

let fromDb = (db: Bun.Sqlite.db): t =>
  make({
    findAll:     params => ItemRepo.findAll(db, params),
    findById:    id     => ItemRepo.findById(db, id),
    insert:      input  => ItemRepo.insert(db, input),
    insertMany:  inputs => ItemRepo.insertMany(db, inputs),
    replace:     input  => ItemRepo.replace(db, input),
    replaceMany: inputs => ItemRepo.replaceMany(db, inputs),
    patch:       (id, input) => ItemRepo.patch(db, id, input),
    delete:      id     => ItemRepo.delete(db, id),
    deleteMany:  ids    => ItemRepo.deleteMany(db, ids),
  })

let mock = (): t => {
  let item: Item.t = {
    id: 1, name: "Mock Item", description: None,
    categoryId: 1, createdAt: 0.0, updatedAt: 0.0,
  }
  make({
    findAll:     _ => Ok([item]),
    findById:    _ => Ok(item),
    insert:      _ => Ok(item),
    insertMany:  inputs => Ok(inputs->Array.map(_ => item)),
    replace:     _ => Ok(item),
    replaceMany: inputs => Ok(inputs->Array.map(_ => item)),
    patch:       (_, _) => Ok(item),
    delete:      _ => Ok(()),
    deleteMany:  _ => Ok(()),
  })
}
