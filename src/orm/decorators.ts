import "reflect-metadata";
import type { EntityClass, Target } from "./types.ts";

export const TABLE_NAME_KEY = "orm:tableName";
export const COLUMNS_KEY = "orm:columns";

export interface ColumnMetadata {
  propertyKey: string;
  type: string;

  isPrimary?: boolean;
}

export function getTableName(target: EntityClass): string | undefined {
  // eslint-disable-next-line @typescript-eslint/no-unsafe-return
  return Reflect.getMetadata(TABLE_NAME_KEY, target);
}

export function getColumnMetadata(target: EntityClass): ColumnMetadata[] {
  // eslint-disable-next-line @typescript-eslint/no-unsafe-return
  return Reflect.getMetadata(COLUMNS_KEY, target) ?? [];
}

export function Entity(tableName: string) {
  return function (constructor: EntityClass) {
    Reflect.defineMetadata(TABLE_NAME_KEY, tableName, constructor);
  };
}

export function Column() {
  return function (target: Target, propertyKey: string) {
    const constructor = target.constructor as EntityClass;
    const columns = getColumnMetadata(constructor);

    const type =
      (
        Reflect.getMetadata(
          "design:type",
          target,
          propertyKey
        ) as EntityClass | null
      )?.name.toLowerCase() ?? "text";

    columns.push({ propertyKey, type });
    Reflect.defineMetadata(COLUMNS_KEY, columns, constructor);
  };
}

export function PrimaryGeneratedColumn() {
  return function (target: Target, propertyKey: string) {
    const constructor = target.constructor as EntityClass;
    const columns = getColumnMetadata(constructor);
    columns.push({ propertyKey, type: "INTEGER", isPrimary: true });
    Reflect.defineMetadata(COLUMNS_KEY, columns, constructor);
  };
}
