/**
 * ORM Layer - Kysely-based data access abstraction.
 *
 * Exports:
 * - Database instance and schema types
 * - Generic Repository base class
 * - Domain-specific repositories (ItemRepository, CategoryRepository)
 * - Type utilities for CRUD operations
 *
 * Usage:
 * ```ts
 * import { itemRepository, categoryRepository } from '@/orm'
 * import { db } from '@/orm/db'
 * import type { ItemRow, NewItem } from '@/orm/database'
 * ```
 */

// Database
export { db } from './db'
export type { DB } from './db'
export type {
  DatabaseSchema,
  ItemTable,
  CategoryTable,
  ItemRow,
  ItemUpdate,
  NewItem,
  CategoryRow,
  CategoryUpdate,
  NewCategory,
} from './database'

// Base Repository
export { Repository } from './Repository'

// Domain Repositories
export { ItemRepository, itemRepository } from './repositories/ItemRepository'
export { CategoryRepository, categoryRepository } from './repositories/CategoryRepository'

// Error handling
export { mapDbError } from './dbErrorMapper'
