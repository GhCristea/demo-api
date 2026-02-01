import type { Database } from "better-sqlite3";

export interface BaseEntity {
  id?: number | string;
}

export type EntityClass<T extends BaseEntity = BaseEntity> = new () => T;

export type Target<T extends BaseEntity = BaseEntity> = InstanceType<
  EntityClass<T>
>;

export type SQLiteDB = Database;
