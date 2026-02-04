import { Repository } from '../Repository'
import { db } from '../db'
import type { ItemRow, NewItem, ItemUpdate } from '../database'

/**
 * Item repository.
 *
 * Provides domain-specific queries for the items table.
 * Extends generic Repository with item-specific business logic.
 */
export class ItemRepository extends Repository<'items'> {
  constructor() {
    super(db, 'items')
  }

  /**
   * Find items by category id.
   */
  async findByCategory(categoryId: number): Promise<ItemRow[]> {
    return this.db
      .selectFrom('items')
      .selectAll()
      .where('categoryId', '=', categoryId)
      .orderBy('name')
      .execute()
  }

  /**
   * Find a single item by name.
   */
  async findByName(name: string): Promise<ItemRow | undefined> {
    return this.db
      .selectFrom('items')
      .selectAll()
      .where('name', '=', name)
      .executeTakeFirst()
  }

  /**
   * Search items by name or description (partial match, case-insensitive).
   */
  async search(query: string): Promise<ItemRow[]> {
    const lowerQuery = `%${query.toLowerCase()}%`
    return this.db
      .selectFrom('items')
      .selectAll()
      .where(eb =>
        eb.or([
          eb(
            eb.fn('lower', [eb.ref('name')]),
            'like',
            lowerQuery,
          ),
          eb(
            eb.fn('lower', [eb.ref('description')]),
            'like',
            lowerQuery,
          ),
        ]),
      )
      .orderBy('name')
      .execute()
  }

  /**
   * Get items with category details (join).
   */
  async findWithCategory(
    limit = 100,
  ): Promise<
    (ItemRow & {
      category?: { id: number; name: string }
    })[]
  > {
    return this.db
      .selectFrom('items')
      .leftJoin('categories', 'items.categoryId', 'categories.id')
      .select([
        'items.id',
        'items.name',
        'items.description',
        'items.categoryId',
        'items.price',
        'items.createdAt',
        'items.updatedAt',
        eb => eb.fn('json_object', [
          'id', 'categories.id',
          'name', 'categories.name',
        ]).as('category'),
      ])
      .limit(limit)
      .execute() as any
  }

  /**
   * Count items in a specific category.
   */
  async countByCategory(categoryId: number): Promise<number> {
    const result = await this.db
      .selectFrom('items')
      .select(eb => eb.fn.count<number>('*').as('count'))
      .where('categoryId', '=', categoryId)
      .executeTakeFirst()

    return result?.count ?? 0
  }

  /**
   * Find items within a price range.
   */
  async findByPriceRange(
    minPrice: number,
    maxPrice: number,
  ): Promise<ItemRow[]> {
    return this.db
      .selectFrom('items')
      .selectAll()
      .where('price', '>=', minPrice)
      .where('price', '<=', maxPrice)
      .orderBy('price')
      .execute()
  }

  /**
   * Create a new item.
   */
  async createItem(data: Omit<NewItem, 'createdAt' | 'updatedAt'>) {
    const now = new Date()
    return this.create({
      ...data,
      createdAt: now,
      updatedAt: now,
    })
  }

  /**
   * Update an item.
   */
  async updateItem(
    id: number,
    data: Omit<ItemUpdate, 'createdAt' | 'updatedAt'>,
  ) {
    return this.update(id, {
      ...data,
      updatedAt: new Date(),
    })
  }
}

/**
 * Singleton instance for dependency injection.
 */
export const itemRepository = new ItemRepository()
