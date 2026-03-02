// Schema definition — inspired by rescript-sql SchemaBuilder DSL
// This file is the single source of truth for table structure.
// Schema.res derives its types from these definitions.
// Db.res derives its DDL SQL from these definitions.
//
// Pattern: define columns as a typed record, constraints as variants.
// No codegen, no npm dep — hand-written but structurally equivalent.

type columnType = Text | Integer | Real
type constraint_ = PrimaryKey | AutoIncrement | NotNull | Unique | ForeignKey({table: string, column: string, onDelete: string})

type column = {
  name: string,
  type_: columnType,
  constraints: array<constraint_>,
  default: option<string>,
}

type table = {
  name: string,
  columns: array<column>,
}

let categories: table = {
  name: "categories",
  columns: [
    {name: "id",          type_: Integer, constraints: [PrimaryKey, AutoIncrement], default: None},
    {name: "name",        type_: Text,    constraints: [NotNull, Unique],           default: None},
    {name: "description", type_: Text,    constraints: [],                          default: None},
    {name: "createdAt",   type_: Real,    constraints: [NotNull],                   default: Some("unixepoch('now','subsec')")},
    {name: "updatedAt",   type_: Real,    constraints: [NotNull],                   default: Some("unixepoch('now','subsec')")},
  ],
}

let items: table = {
  name: "items",
  columns: [
    {name: "id",          type_: Integer, constraints: [PrimaryKey, AutoIncrement], default: None},
    {name: "name",        type_: Text,    constraints: [NotNull],                   default: None},
    {name: "description", type_: Text,    constraints: [],                          default: None},
    {name: "categoryId",  type_: Integer, constraints: [NotNull, ForeignKey({table: "categories", column: "id", onDelete: "RESTRICT"})], default: None},
    {name: "createdAt",   type_: Real,    constraints: [NotNull],                   default: Some("unixepoch('now','subsec')")},
    {name: "updatedAt",   type_: Real,    constraints: [NotNull],                   default: Some("unixepoch('now','subsec')")},
  ],
}

let tables = [categories, items]
