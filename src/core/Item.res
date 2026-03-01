// Item domain type — source of truth
// toJson is the single serialization point used by all handlers
// fromRow maps a raw SQLite row to the typed record

type t = {
  id: int,
  name: string,
  description: option<string>,
  createdAt: float,
  updatedAt: float,
}

type createInput = {
  name: string,
  description: option<string>,
}

type updateInput = {
  name: option<string>,
  description: option<string>,
}

let toJson = (item: t): Js.Json.t =>
  Js.Json.object_(
    Js.Dict.fromArray([
      ("id", Js.Json.number(Int.toFloat(item.id))),
      ("name", Js.Json.string(item.name)),
      ("description", switch item.description {
        | Some(d) => Js.Json.string(d)
        | None => Js.Json.null
      }),
      ("createdAt", Js.Json.number(item.createdAt)),
      ("updatedAt", Js.Json.number(item.updatedAt)),
    ])
  )

// Maps a raw SQLite row (Js.t) to Item.t
// Called in ItemRepo after every query
let fromRow = (row: {"id": int, "name": string, "description": Js.Nullable.t<string>, "createdAt": float, "updatedAt": float}): t => {
  id: row["id"],
  name: row["name"],
  description: row["description"]->Js.Nullable.toOption,
  createdAt: row["createdAt"],
  updatedAt: row["updatedAt"],
}
