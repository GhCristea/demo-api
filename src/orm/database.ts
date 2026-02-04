import type { Generated, Insertable, Selectable, Updateable } from 'kysely'

/**
 * Item table schema.
 * Represents a product or service in the catalog.
 */
export interface ItemTable {
  id: Generated<number>
  name: string
  description: string | null
  categoryId: number
  price: number
  createdAt: Generated<Date>
  updatedAt: Date
}

/**
 * Category table schema.
 * Represents a product/service category.
 */
export interface CategoryTable {
  id: Generated<number>
  name: string
  description: string | null
  createdAt: Generated<Date>
  updatedAt: Date
}

/**
 * Complete database schema definition.
 * Define all tables here for type-safe queries.
 */
export interface DatabaseSchema {
  items: ItemTable
  categories: CategoryTable
}

/**
 * Type exports for convenient usage.
 * Example: `type ItemRow = Selectable<ItemTable>`
 */
export type ItemRow = Selectable<ItemTable>
export type NewItem = Insertable<ItemTable>
export type ItemUpdate = Updateable<ItemTable>

export type CategoryRow = Selectable<CategoryTable>
export type NewCategory = Insertable<CategoryTable>
export type CategoryUpdate = Updateable<CategoryTable>
