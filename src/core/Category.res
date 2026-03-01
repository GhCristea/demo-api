// Category domain type
// toJson is the single serialization point
// fromRow maps a Schema.Categories.row to Category.t

type t = {
  id:          int,
  name:        string,
  description: option<string>,
  createdAt:   float,
  updatedAt:   float,
}

let toJson = (c: t): Js.Json.t =>
  Json.obj([
    ("id",          Json.int(c.id)),
    ("name",        Json.str(c.name)),
    ("description", Json.opt(c.description)),
    ("createdAt",   Json.num(c.createdAt)),
    ("updatedAt",   Json.num(c.updatedAt)),
  ])

let fromRow = (row: Schema.Categories.row): t => {
  id:          row["id"],
  name:        row["name"],
  description: row["description"]->Js.Nullable.toOption,
  createdAt:   row["createdAt"],
  updatedAt:   row["updatedAt"],
}
