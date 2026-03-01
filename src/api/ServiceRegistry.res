// Service registry — single wiring point for all services
// Initialised once at startup via init(db)
// Avoids threading db through every call site
// To add a new resource: add its service here and call fromDb in init

let items: ref<ItemService.t> = ref({
  list: () => Error(AppError.Internal("ServiceRegistry not initialised")),
  get: _ => Error(AppError.Internal("ServiceRegistry not initialised")),
  create: _ => Error(AppError.Internal("ServiceRegistry not initialised")),
  update: (_, _) => Error(AppError.Internal("ServiceRegistry not initialised")),
  delete: _ => Error(AppError.Internal("ServiceRegistry not initialised")),
})

let init = (db: Bun.Sqlite.db): unit => {
  items := ItemService.fromDb(db)
}
