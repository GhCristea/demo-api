// Category domain type
// Extended shape: id, name, description?, createdAt, updatedAt
// toJson is the single serialization point
// fromRow maps a Schema.Categories.row to Category.t

type t = {
  id: int,
  name: string,
  description: option<string>,
  createdAt: float,
  updatedAt: float,
}

let toJson = (c: t): Js.Json.t =>
  Js.Json.object_(
    Js.Dict.fromArray([
      ("id",          Js.Json.number(Int.toFloat(c.id))),
      ("name",        Js.Json.string(c.name)),
      ("description", switch c.description {
        | Some(d) => Js.Json.string(d)
        | None    => Js.Json.null
      }),
      ("createdAt",   Js.Json.number(c.createdAt)),
      ("updatedAt",   Js.Json.number(c.updatedAt)),
    ])
  )

let fromRow = (row: Schema.Categories.row): t => {
  id:          row["id"],
  name:        row["name"],
  description: row["description"]->Js.Nullable.toOption,
  createdAt:   row["createdAt"],
  updatedAt:   row["updatedAt"],
}
