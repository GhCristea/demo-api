import { col, Table } from "../orm/dialect.ts";

export const TABLE = {
  Items: "items",
  Categories: "categories"
} as const;

const ItemSchema = {
  id: col("INTEGER", { primaryKey: true }),
  name: col("TEXT"),
  categoryId: col("INTEGER", { references: `${TABLE.Categories}(id)` }),
  categoryName: col("TEXT", { nullable: true })
};

const CategorySchema = {
  id: col("INTEGER", { primaryKey: true }),
  name: col("TEXT")
};

export const Items = new Table(TABLE.Items, ItemSchema);
export const Categories = new Table(TABLE.Categories, CategorySchema);
