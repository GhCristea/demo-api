// Shared SQLite query primitives — one try/catch for the whole codebase
// All helpers return result<_, AppError.t> — no exceptions escape this module
// Repos use these instead of writing try/catch directly

type db = Bun.Sqlite.db

let try_ = (f: unit => 'a): result<'a, AppError.t> =>
  try Ok(f())
  catch {
  | Js.Exn.Error(e) => Error(AppError.Internal(Js.Exn.message(e)->Option.getOr("DB error")))
  }

// SELECT … — returns all matching rows
let all = (db: db, sql: string, params): result<array<'row>, AppError.t> =>
  try_(() => db->Bun.Sqlite.prepare(sql)->Bun.Sqlite.all(params))

// SELECT … LIMIT 1 — returns Some(row) or None
let getOpt = (db: db, sql: string, params): result<option<'row>, AppError.t> =>
  try_(() => db->Bun.Sqlite.prepare(sql)->Bun.Sqlite.get(params)->Js.Nullable.toOption)

// SELECT / INSERT / UPDATE RETURNING — maps row or returns notFound error
let getOrErr = (db: db, sql: string, params, ~err: AppError.t, map: 'row => 'a): result<'a, AppError.t> =>
  getOpt(db, sql, params)
  ->Result.flatMap(opt => opt->Option.map(map)->Result.fromOption(err))

// DELETE / UPDATE without RETURNING — checks changes > 0
let runOrNotFound = (db: db, sql: string, params, ~notFound: AppError.t): result<unit, AppError.t> =>
  try_(() => db->Bun.Sqlite.prepare(sql)->Bun.Sqlite.run(params))
  ->Result.flatMap(meta => meta["changes"] > 0 ? Ok(()) : Error(notFound))

// Wraps f in a SQLite transaction — any exception rolls back + maps to AppError.Internal
let inTransaction = (db: db, f: unit => 'a): result<'a, AppError.t> =>
  try_(() => db->Bun.Sqlite.transaction(_ => f())([]))
