// Entry point — open db, init services, start server
// Intentionally minimal: no business logic here

let port = switch Js.Dict.get(Node.Process.process["env"], "PORT") {
| Some(p) => p->Int.fromString->Option.getOr(3001)
| None => 3001
}

let db = Db.open_()
ServiceRegistry.init(db)
Server.start(~port, ~db)
