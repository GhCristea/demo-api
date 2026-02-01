import { getTableName, getColumnMetadata } from "./decorators.ts";
import type { BaseEntity, EntityClass, SQLiteDB } from "./types.ts";
import { QueryBuilder } from "./QueryBuilder.ts";
import { validate } from "./validation.ts";
import { ValidationError } from "../errors/HttpError.ts";

export class Repository<T extends BaseEntity = BaseEntity> {
  constructor(
    private db: SQLiteDB,
    private entityClass: EntityClass<T>
  ) {}

  private get tableName() {
    const tableName = getTableName(this.entityClass);
    if (!tableName) {
      throw new Error(`Entity ${this.entityClass.name} has no table name.`);
    }
    return tableName;
  }

  private get validColumns() {
    const cols = getColumnMetadata(this.entityClass);
    return cols.map((c) => c.propertyKey);
  }

  public mapToEntity = (row: unknown): T => {
    if (!row || typeof row !== "object") {
      throw new Error(`Query returned invalid row: ${String(row)}`);
    }
    const entity = new this.entityClass();
    Object.assign(entity, row);
    return entity;
  };

  getQuery() {
    return new QueryBuilder<T>(this.db, this.tableName, this.mapToEntity);
  }

  findAll() {
    const rows = this.db.prepare(`SELECT * FROM ${this.tableName}`).all();
    return rows.map(this.mapToEntity);
  }

  findById(id: number | bigint) {
    const row = this.db
      .prepare(`SELECT * FROM ${this.tableName} WHERE id = ?`)
      .get(id);

    return row ? this.mapToEntity(row) : undefined;
  }

  create(data: Partial<Omit<T, "id">>) {
    const errors = validate(this.entityClass, data, false);
    if (errors.length > 0) {
      throw new ValidationError(errors);
    }

    const validKeys = new Set(this.validColumns);

    const entries = Object.entries(data);
    const validEntries = entries.filter(([k, v]) => {
      return v !== undefined && validKeys.has(k);
    });

    if (validEntries.length === 0) {
      throw new Error("No valid columns provided for insert");
    }

    const keys = validEntries.map(([k]) => k);
    const values = validEntries.map(([_, v]) => v);

    const placeholders = keys.map(() => "?").join(", ");
    const columns = keys.join(", ");

    const stmt = this.db.prepare(
      `INSERT INTO ${this.tableName} (${columns}) VALUES (${placeholders})`
    );

    return stmt.run(...values);
  }

  update(id: number | string, data: Partial<Omit<T, "id">>) {
    const errors = validate(this.entityClass, data, true);
    if (errors.length > 0) {
      throw new ValidationError(errors);
    }

    const validKeys = new Set(this.validColumns);

    const entries = Object.entries(data).filter(([k, v]) => {
      return v !== undefined && validKeys.has(k);
    });

    if (entries.length === 0) {
      throw new Error("No valid data provided for update");
    }

    const setClause = entries.map(([k]) => `${k} = ?`).join(", ");
    const values = entries.map(([_, v]) => v);
    values.push(id);

    const stmt = this.db.prepare(
      `UPDATE ${this.tableName} SET ${setClause} WHERE id = ?`
    );

    return stmt.run(...values);
  }

  delete(id: number | string) {
    return this.db
      .prepare(`DELETE FROM ${this.tableName} WHERE id = ?`)
      .run(id);
  }
}
