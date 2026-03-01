// Database initialisation
// Opens bun:sqlite and runs the migration SQL
// Returns the db value — threaded as a parameter throughout the app (pure DI)

let migrate = (db: Bun.Sqlite.db): unit => {
  db->Bun.Sqlite.exec(
    `CREATE TABLE IF NOT EXISTS categories (
      id          INTEGER PRIMARY KEY AUTOINCREMENT,
      name        TEXT    NOT NULL,
      description TEXT,
      createdAt   REAL    NOT NULL DEFAULT (unixepoch('now', 'subsec')),
      updatedAt   REAL    NOT NULL DEFAULT (unixepoch('now', 'subsec'))
    );`,
  )
  db->Bun.Sqlite.exec(
    `CREATE TABLE IF NOT EXISTS items (
      id          INTEGER PRIMARY KEY AUTOINCREMENT,
      name        TEXT    NOT NULL,
      description TEXT,
      categoryId  INTEGER NOT NULL REFERENCES categories(id),
      createdAt   REAL    NOT NULL DEFAULT (unixepoch('now', 'subsec')),
      updatedAt   REAL    NOT NULL DEFAULT (unixepoch('now', 'subsec'))
    );`,
  )
}

let open_ = (): Bun.Sqlite.db => {
  let path = switch Js.Dict.get(Node.Process.process["env"], "DB_PATH") {
  | Some(p) => p
  | None    => ":memory:"
  }
  let db = Bun.Sqlite.open_(path)
  db->migrate
  db
}
