import { Kysely, SqliteDialect, CamelCasePlugin } from 'kysely'
import Database from 'better-sqlite3'
import type { DatabaseSchema } from './database'

/**
 * Initialize and export the database instance.
 * Supports SQLite with camelCase plugin for automatic snake_case <-> camelCase conversion.
 *
 * Usage:
 * ```ts
 * import { db } from './orm/db'
 * const users = await db.selectFrom('users').selectAll().execute()
 * ```
 */
const dialect = new SqliteDialect({
  database: async () => new Database(process.env.DB_PATH || ':memory:'),
})

export const db = new Kysely<DatabaseSchema>({
  dialect,
  plugins: [new CamelCasePlugin()],
})

/**
 * Export database instance for dependency injection and testing.
 */
export type DB = typeof db
