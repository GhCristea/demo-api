// Database initialisation
// DDL is derived from Schema_ definitions
// categories must be created before items (FK dependency)

let migrate = (db: Bun.Sqlite.db): unit => {
  // Run each statement separately — exec does not support multi-statement strings in all Bun versions
  db->Bun.Sqlite.exec(
    `CREATE TABLE IF NOT EXISTS categories (
      id          INTEGER PRIMARY KEY AUTOINCREMENT,
      name        TEXT    NOT NULL UNIQUE,
      description TEXT,
      createdAt   REAL    NOT NULL DEFAULT (unixepoch('now','subsec')),
      updatedAt   REAL    NOT NULL DEFAULT (unixepoch('now','subsec'))
    );`,
  )
  db->Bun.Sqlite.exec(
    `CREATE TABLE IF NOT EXISTS items (
      id          INTEGER PRIMARY KEY AUTOINCREMENT,
      name        TEXT    NOT NULL,
      description TEXT,
      categoryId  INTEGER NOT NULL,
      createdAt   REAL    NOT NULL DEFAULT (unixepoch('now','subsec')),
      updatedAt   REAL    NOT NULL DEFAULT (unixepoch('now','subsec')),
      FOREIGN KEY (categoryId) REFERENCES categories(id) ON DELETE RESTRICT
    );`,
  )
}

let open_ = (): Bun.Sqlite.db => {
  let path = switch Js.Dict.get(Node.Process.process["env"], "DB_PATH") {
  | Some(p) => p
  | None => ":memory:"
  }
  let db = Bun.Sqlite.open_(path)
  db->migrate
  db
}
