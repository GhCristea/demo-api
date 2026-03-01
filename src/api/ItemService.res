// Item business logic
// DI: deps record holds all data-access functions
// Swap deps.repo for a mock in tests — no framework needed

type repo = {
  findAll: unit => result<array<Item.t>, AppError.t>,
  findById: int => result<Item.t, AppError.t>,
  insert: Schemas.createInput => result<Item.t, AppError.t>,
  patch: (int, Schemas.updateInput) => result<Item.t, AppError.t>,
  delete: int => result<unit, AppError.t>,
}

type t = {
  list: unit => result<array<Item.t>, AppError.t>,
  get: int => result<Item.t, AppError.t>,
  create: Schemas.createInput => result<Item.t, AppError.t>,
  update: (int, Schemas.updateInput) => result<Item.t, AppError.t>,
  delete: int => result<unit, AppError.t>,
}

let make = (repo: repo): t => {
  list: repo.findAll,
  get: repo.findById,
  create: repo.insert,
  update: repo.patch,
  delete: repo.delete,
}

// Wire to real DB — called once at startup with the open db value
let fromDb = (db: Bun.Sqlite.db): t =>
  make({
    findAll: () => ItemRepo.findAll(db),
    findById: id => ItemRepo.findById(db, id),
    insert: input => ItemRepo.insert(db, input),
    patch: (id, input) => ItemRepo.patch(db, id, input),
    delete: id => ItemRepo.delete(db, id),
  })
