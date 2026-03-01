// Bun FFI bindings
// Covers: HTTP server, SQLite, URL parsing (pathname + searchParams), process
// Keep bindings minimal — only bind what is used

// ─── HTTP ───────────────────────────────────────────────────────────────────────────────────

type request
type response

@send external method: request => string = "method"
@send external url: request => string = "url"
@send external json: request => promise<Js.Json.t> = "json"
@get  external status: response => int = "status"

@new external makeResponse: (string, {"status": int, "headers": {"content-type": string}}) => response = "Response"

let jsonResponse = (~status: int=200, data: Js.Json.t): response =>
  makeResponse(
    Js.Json.stringify(data),
    {"status": status, "headers": {"content-type": "application/json"}},
  )

type serveOptions = {
  fetch: request => promise<response>,
  port: int,
  hostname: string,
}

type server = {hostname: string, port: int}

@val external serve: serveOptions => server = "Bun.serve"
@val external exit: int => unit = "Bun.exit"

// ─── URL ────────────────────────────────────────────────────────────────────────────────────

type urlObj
@new external makeUrl: string => urlObj = "URL"
@get external pathname: urlObj => string = "pathname"
@send external searchParamsGet: (urlObj, string) => Js.Nullable.t<string> = "searchParams.get"

let getPathname = (rawUrl: string): string => rawUrl->makeUrl->pathname
let searchParam = (u: urlObj, key: string): Js.Nullable.t<string> => u->searchParamsGet(key)

// ─── SQLite ─────────────────────────────────────────────────────────────────────────────────

module Sqlite = {
  type db
  type statement<'a>

  @module("bun:sqlite") @new external open_: string => db = "Database"
  @send external exec:        (db, string) => unit = "exec"
  @send external prepare:     (db, string) => statement<'a> = "prepare"
  @send external all:         (statement<'a>, array<'b>) => array<'a> = "all"
  @send external get:         (statement<'a>, array<'b>) => Js.Nullable.t<'a> = "get"
  @send external run:         (statement<'a>, array<'b>) => {"changes": int, "lastInsertRowid": float} = "run"
  @send external close:       db => unit = "close"
  // transaction(fn) returns a wrapped fn — call the result to execute inside a transaction
  @send external transaction: (db, array<'a> => 'ret) => (array<'a> => 'ret) = "transaction"
}
