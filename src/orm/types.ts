import type { Database } from "better-sqlite3";

export interface BaseEntity {
  id?: number | string;
}

export type Constructor<
  T extends BaseEntity = BaseEntity,
  A extends unknown[] = unknown[]
> = new (...args: A) => T;

export type SQLiteDB = Database;
