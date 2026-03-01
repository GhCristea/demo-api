// Service registry — single wiring point for all services
// Initialised once at startup via init(db)
// Adding a new resource: add its service field here, wire in init

let items: ref<ItemService.t> = ref({
  findAll:     _ => Error(AppError.Internal("ServiceRegistry not initialised")),
  findById:    _ => Error(AppError.Internal("ServiceRegistry not initialised")),
  insert:      _ => Error(AppError.Internal("ServiceRegistry not initialised")),
  insertMany:  _ => Error(AppError.Internal("ServiceRegistry not initialised")),
  replace:     _ => Error(AppError.Internal("ServiceRegistry not initialised")),
  replaceMany: _ => Error(AppError.Internal("ServiceRegistry not initialised")),
  delete:      _ => Error(AppError.Internal("ServiceRegistry not initialised")),
  deleteMany:  _ => Error(AppError.Internal("ServiceRegistry not initialised")),
})

let categories: ref<CategoryRepo.db => result<Category.t, AppError.t>> =
  ref(_ => Error(AppError.Internal("ServiceRegistry not initialised")))

let init = (db: Bun.Sqlite.db): unit => {
  items := ItemService.fromDb(db)
  categories := CategoryRepo.findByItemId(db, _)
}
