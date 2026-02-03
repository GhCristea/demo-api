import { Repository } from '../Repository'
import { db } from '../db'
import type { CategoryRow, NewCategory, CategoryUpdate } from '../database'

/**
 * Category repository.
 *
 * Provides domain-specific queries for the categories table.
 * Extends generic Repository with category-specific business logic.
 */
export class CategoryRepository extends Repository<'categories'> {
  constructor() {
    super(db, 'categories')
  }

  /**
   * Find a category by exact name match.
   */
  async findByName(name: string): Promise<CategoryRow | undefined> {
    return this.db
      .selectFrom('categories')
      .selectAll()
      .where('name', '=', name)
      .executeTakeFirst()
  }

  /**
   * Search categories by name (partial match, case-insensitive).
   */
  async searchByName(query: string): Promise<CategoryRow[]> {
    return this.db
      .selectFrom('categories')
      .selectAll()
      .where(eb =>
        eb(
          eb.fn('lower', [eb.ref('name')]),
          'like',
          `%${query.toLowerCase()}%`,
        ),
      )
      .orderBy('name')
      .execute()
  }

  /**
   * Get all categories sorted by name.
   */
  async findAllSorted(): Promise<CategoryRow[]> {
    return this.db
      .selectFrom('categories')
      .selectAll()
      .orderBy('name')
      .execute()
  }

  /**
   * Create a new category.
   */
  async createCategory(data: Omit<NewCategory, 'createdAt' | 'updatedAt'>) {
    const now = new Date()
    return this.create({
      ...data,
      createdAt: now,
      updatedAt: now,
    })
  }

  /**
   * Update a category.
   */
  async updateCategory(
    id: number,
    data: Omit<CategoryUpdate, 'createdAt' | 'updatedAt'>,
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
export const categoryRepository = new CategoryRepository()
