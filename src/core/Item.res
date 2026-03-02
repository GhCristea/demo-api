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
  Json.obj([
    ("id",          Json.int(item.id)),
    ("name",        Json.str(item.name)),
    ("description", Json.opt(item.description)),
    ("categoryId",  Json.int(item.categoryId)),
    ("createdAt",   Json.num(item.createdAt)),
    ("updatedAt",   Json.num(item.updatedAt)),
  ])

let fromRow = (row: Schema.Items.row): t => {
  id:          row["id"],
  name:        row["name"],
  description: row["description"]->Js.Nullable.toOption,
  categoryId:  row["categoryId"],
  createdAt:   row["createdAt"],
  updatedAt:   row["updatedAt"],
}
