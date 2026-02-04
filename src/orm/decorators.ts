import "reflect-metadata";
import type { ZodType } from "zod";
import type { BaseEntity, Constructor } from "./types.ts";

export const TABLE_NAME_KEY = "orm:tableName";
export const COLUMNS_KEY = "orm:columns";
export const VALIDATION_KEY = "orm:validation";

export interface ColumnMetadata {
  propertyKey: string;
  type: string;
  foreignKey?: string;
  isPrimary?: boolean;
}

export function getTableName(target: Constructor) {
  return Reflect.getMetadata(TABLE_NAME_KEY, target) as string | undefined;
}

export function getColumnMetadata(target: Constructor) {
  return (Reflect.getMetadata(COLUMNS_KEY, target) ?? []) as ColumnMetadata[];
}

export function getValidationRules(target: Constructor) {
  return (Reflect.getMetadata(VALIDATION_KEY, target) ?? {}) as Record<
    string,
    ZodType
  >;
}

export function Entity(tableName: string) {
  return function (constructor: Constructor) {
    Reflect.defineMetadata(TABLE_NAME_KEY, tableName, constructor);
  };
}

interface ColumnOptions {
  rule?: ZodType;
  foreignKey?: string;
}

export function Column(options?: ColumnOptions) {
  return function (target: BaseEntity, propertyKey: string) {
    const constructor = target.constructor as Constructor;

    const columns = getColumnMetadata(constructor);
    const type = "TEXT";

    columns.push({
      propertyKey,
      type,
      ...(options?.foreignKey ? { foreignKey: options.foreignKey } : {})
    });
    Reflect.defineMetadata(COLUMNS_KEY, columns, constructor);

    if (options?.rule) {
      const rules = getValidationRules(constructor);
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
