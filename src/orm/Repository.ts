import { getTableName } from "./decorators.ts";
import type { BaseEntity, Constructor, SQLiteDB } from "./types.ts";
import { QueryBuilder } from "./QueryBuilder.ts";
import { getSchema } from "./schemaFactory.ts";

export class Repository<T extends BaseEntity = BaseEntity> {
  constructor(
    private db: SQLiteDB,
    private entityClass: Constructor<T>
  ) {}

  private get tableName() {
    const tableName = getTableName(this.entityClass);
    if (!tableName) {
      throw new Error(`Entity ${this.entityClass.name} has no table name.`);
    }
    return tableName;
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

  findById(id: T["id"]) {
    const row = this.db
      .prepare(`SELECT * FROM ${this.tableName} WHERE id = ?`)
      .get(id);

    return row ? this.mapToEntity(row) : undefined;
  }

  create(data: Partial<Omit<T, "id">>) {
    const schema = getSchema(this.entityClass);
    const validData = schema.parse(data);

    const entries = Object.entries(validData);

    if (entries.length === 0) {
      throw new Error("No valid columns provided for insert");
    }

    const keys = entries.map(([k]) => k);
    const values = entries.map(([_, v]) => v);

    const placeholders = keys.map(() => "?").join(", ");
    const columns = keys.join(", ");

    const stmt = this.db.prepare(
      `INSERT INTO ${this.tableName} (${columns}) VALUES (${placeholders})`
    );

    return stmt.run(...values);
  }

  update(id: T["id"], data: Partial<Omit<T, "id">>) {
    const schema = getSchema(this.entityClass).partial();
    const validData = schema.parse(data);

    const entries = Object.entries(validData);

    if (entries.length === 0) {
      throw new Error("No valid data provided for update");
    }

    const setClause = entries.map(([k]) => `${k} = ?`).join(", ");
    const values = entries.map(([_, v]) => v) as T[keyof T][];
    values.push(id);

    const stmt = this.db.prepare(
      `UPDATE ${this.tableName} SET ${setClause} WHERE id = ?`
    );

    return stmt.run(...values);
  }

  delete(id: T["id"]) {
    return this.db
      .prepare(`DELETE FROM ${this.tableName} WHERE id = ?`)
      .run(id);
  }
}
