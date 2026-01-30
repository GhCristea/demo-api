import type { EntityClass } from "./types.ts";

type Target<T extends EntityClass = EntityClass> = InstanceType<T>;
interface ColumnDefinition {
  propertyKey: string;
  type: "INTEGER" | "TEXT" | "REAL" | "BLOB";
  isPrimary?: boolean;
  isNullable?: boolean;
}

export const columnMetadata = new WeakMap<EntityClass, ColumnDefinition[]>();
const tableMetadata = new WeakMap<EntityClass, string>();

export function Entity(tableName: string) {
  return function (constructor: EntityClass) {
    tableMetadata.set(constructor, tableName);
  };
}

export function getTableName(entity: EntityClass) {
  return tableMetadata.get(entity);
}

function addColumnMetadata(target: Target, definition: ColumnDefinition) {
  const constructor = target.constructor as EntityClass;
  const columns = columnMetadata.get(constructor) || [];
  columns.push(definition);
  columnMetadata.set(constructor, columns);
}

export function Column(type: "INTEGER" | "TEXT" | "REAL" = "TEXT") {
  return function (target: Target, propertyKey: string) {
    addColumnMetadata(target, { propertyKey, type });
  };
}

export function PrimaryGeneratedColumn() {
  return function (target: Target, propertyKey: string) {
    addColumnMetadata(target, {
      propertyKey,
      type: "INTEGER",
      isPrimary: true
    });
  };
}
