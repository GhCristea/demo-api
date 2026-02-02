import "reflect-metadata";
import type { ZType } from "../lib/z.ts";
import type { BaseEntity, Constructor } from "./types.ts";

export const TABLE_NAME_KEY = "orm:tableName";
export const COLUMNS_KEY = "orm:columns";
export const VALIDATION_KEY = "orm:validation";

export interface ColumnMetadata {
  propertyKey: string;
  type: string;

  isPrimary?: boolean;
}

export function getTableName(target: Constructor) {
  return Reflect.getMetadata(TABLE_NAME_KEY, target) as string | undefined;
}

export function getColumnMetadata(target: Constructor) {
  return (Reflect.getMetadata(COLUMNS_KEY, target) ?? []) as ColumnMetadata[];
}

export function getValidationRules<T>(target: Constructor) {
  return (Reflect.getMetadata(VALIDATION_KEY, target) ?? {}) as Record<
    string,
    ZType<T>
  >;
}

export function Entity(tableName: string) {
  return function (constructor: Constructor) {
    Reflect.defineMetadata(TABLE_NAME_KEY, tableName, constructor);
  };
}

interface ColumnOptions<T> {
  rule?: ZType<T>;
}

export function Column<T>(options?: ColumnOptions<T>) {
  return function (target: BaseEntity, propertyKey: string) {
    const constructor = target.constructor as Constructor;

    const columns = getColumnMetadata(constructor);
    const type = "TEXT";

    columns.push({ propertyKey, type });
    Reflect.defineMetadata(COLUMNS_KEY, columns, constructor);
    if (options?.rule) {
      const rules = getValidationRules<T>(constructor);
      rules[propertyKey] = options.rule;
      Reflect.defineMetadata(VALIDATION_KEY, rules, constructor);
    }
  };
}

export function PrimaryGeneratedColumn() {
  return function (target: BaseEntity, propertyKey: string) {
    const constructor = target.constructor as Constructor;
    const columns = getColumnMetadata(constructor);
    columns.push({ propertyKey, type: "INTEGER", isPrimary: true });
    Reflect.defineMetadata(COLUMNS_KEY, columns, constructor);
  };
}
