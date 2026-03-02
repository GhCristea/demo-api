// Immutable service registry — created once at startup, passed explicitly
// Adding a resource: add field to t, wire in make

type t = {
  items:      ItemService.t,
  categories: CategoryService.t,
}

let make = (db: Bun.Sqlite.db): t => {
  items:      ItemService.fromDb(db),
  categories: CategoryService.fromDb(db),
}
