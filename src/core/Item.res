// Item domain type — source of truth
// categoryId is a required FK to categories
// toJson is the single serialization point used by all handlers
// fromRow maps a Schema.Items.row to Item.t

type t = {
  id:          int,
  name:        string,
  description: option<string>,
  categoryId:  int,
  createdAt:   float,
  updatedAt:   float,
}

let toJson = (item: t): Js.Json.t =>
  Js.Json.object_(
    Js.Dict.fromArray([
      ("id",          Js.Json.number(Int.toFloat(item.id))),
      ("name",        Js.Json.string(item.name)),
      ("description", switch item.description {
        | Some(d) => Js.Json.string(d)
        | None    => Js.Json.null
      }),
      ("categoryId",  Js.Json.number(Int.toFloat(item.categoryId))),
      ("createdAt",   Js.Json.number(item.createdAt)),
      ("updatedAt",   Js.Json.number(item.updatedAt)),
    ])
  )

let fromRow = (row: Schema.Items.row): t => {
  id:          row["id"],
  name:        row["name"],
  description: row["description"]->Js.Nullable.toOption,
  categoryId:  row["categoryId"],
  createdAt:   row["createdAt"],
  updatedAt:   row["updatedAt"],
}
