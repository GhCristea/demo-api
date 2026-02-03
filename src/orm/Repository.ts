import type { Expression, ExpressionBuilder, Kysely } from 'kysely'
import type { DatabaseSchema } from './database'

/**
 * Generic repository abstraction using Kysely.
 *
 * Provides common CRUD operations for any table in the schema.
 * Enforces separation of concerns: domain logic separate from persistence.
 *
 * @example
 * ```ts
 * class UserRepository extends Repository<'users'> {
 *   constructor() {
 *     super(db, 'users')
 *   }
 *
 *   async findByEmail(email: string) {
 *     return this.query().where('email', '=', email).executeTakeFirst()
 *   }
 * }
 * ```
 */
export abstract class Repository<T extends keyof DatabaseSchema> {
  constructor(
    protected db: Kysely<DatabaseSchema>,
    protected tableName: T,
  ) {}

  /**
   * Get the query builder for this table.
   * Allows domain-specific repos to build custom queries.
   */
  protected query() {
    return this.db.selectFrom(this.tableName).selectAll()
  }

  /**
   * Find a single record by primary key (id).
   */
  async findById(id: number) {
    return this.db
      .selectFrom(this.tableName)
      .selectAll()
      .where('id' as never, '=', id as never)
      .executeTakeFirst()
  }

  /**
   * Find all records with optional limit.
   */
  async findAll(limit = 100) {
    return this.db
      .selectFrom(this.tableName)
      .selectAll()
      .limit(limit)
      .execute()
  }

  /**
   * Create a new record.
   * Returns the inserted row with generated fields.
   */
  async create(data: Record<string, any>) {
    return this.db
      .insertInto(this.tableName)
      .values(data as never)
      .returningAll()
      .executeTakeFirstOrThrow()
  }

  /**
   * Update a record by id.
   * Returns the updated row or undefined if not found.
   */
  async update(id: number, data: Record<string, any>) {
    return this.db
      .updateTable(this.tableName)
      .set(data as never)
      .where('id' as never, '=', id as never)
      .returningAll()
      .executeTakeFirst()
  }

  /**
   * Delete a record by id.
   */
  async delete(id: number) {
    return this.db
      .deleteFrom(this.tableName)
      .where('id' as never, '=', id as never)
      .execute()
  }

  /**
   * Count total records in the table.
   */
  async count() {
    const result = await this.db
      .selectFrom(this.tableName)
      .select(eb => eb.fn.count<number>('*').as('count'))
      .executeTakeFirst()

    return result?.count ?? 0
  }

  /**
   * Check if a record exists by id.
   */
  async exists(id: number) {
    const result = await this.db
      .selectFrom(this.tableName)
      .select('id')
      .where('id' as never, '=', id as never)
      .executeTakeFirst()

    return !!result
  }
}
