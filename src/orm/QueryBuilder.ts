import type { SQLiteDB, RunResult } from "./types.ts";
import type { Table, Infer, TableSchema } from "./dialect.ts";

export class QueryBuilder<ResultType> {
  private query = "";
  private params: unknown[] = [];
  private tableName: string;
  private table: Table;

  constructor(
    private db: SQLiteDB,
    table: Table
  ) {
    this.tableName = table.tableName;
    this.table = table;
  }

  select(): this {
    this.query = `SELECT * FROM ${this.tableName} ${this.query}`;
    return this;
  }

  selectColumns(cols: (keyof ResultType)[]): this {
    this.query = `SELECT ${cols.join(", ")} FROM ${this.tableName} ${this.query}`;
    return this;
  }

  selectRaw(sql: string): this {
    this.query = `SELECT ${sql} FROM ${this.tableName} ${this.query}`;
    return this;
  }

  where<K extends keyof ResultType | string>(
    column: K,
    operator: "=" | ">" | "<" | "LIKE",
    value: K extends keyof ResultType ? ResultType[K] : unknown
  ): this {
    const clause = this.query.includes("WHERE") ? "AND" : "WHERE";
    this.query += ` ${clause} ${String(column)} ${operator} ?`;
    this.params.push(value);
    return this;
  }

  limit(limit: number): this {
    this.query += ` LIMIT ${String(limit)}`;
    return this;
  }

  leftJoin<S extends TableSchema>(table: Table<S>, on: string) {
    return this.join("LEFT", table, on);
  }

  innerJoin<S extends TableSchema>(table: Table<S>, on: string) {
    return this.join("INNER", table, on);
  }

  private join<S extends TableSchema>(
    type: "LEFT" | "INNER",
    table: Table<S>,
    on: string
  ): QueryBuilder<ResultType & Infer<S>> {
    this.query += ` ${type} JOIN ${table.tableName} ON ${on}`;
    return this as unknown as QueryBuilder<ResultType & Infer<S>>;
  }

  get(): ResultType[] {
    const stmt = this.db.prepare(this.query);
    return stmt.all(this.params) as ResultType[];
  }

  first(): ResultType | undefined {
    const stmt = this.db.prepare(this.query + " LIMIT 1");
    return stmt.get(this.params) as ResultType | undefined;
  }

  create(data: Partial<ResultType>): RunResult {
    const keys = Object.keys(data);
    const placeholders = keys.map(() => "?").join(", ");
    const sql = `INSERT INTO ${this.tableName} (${keys.join(", ")}) VALUES (${placeholders})`;

    return this.db.prepare(sql).run(...Object.values(data));
  }

  update(id: string | number, data: Partial<ResultType>): RunResult {
    const keys = Object.keys(data);
    const setClause = keys.map((k) => `${k} = ?`).join(", ");
    const pk = this.getPrimaryKey();

    const sql = `UPDATE ${this.tableName} SET ${setClause} WHERE ${pk} = ?`;
    return this.db.prepare(sql).run(...Object.values(data), id);
  }

  delete(id: string | number): RunResult {
    const pk = this.getPrimaryKey();
    const sql = `DELETE FROM ${this.tableName} WHERE ${pk} = ?`;
    return this.db.prepare(sql).run(id);
  }

  findById(id: string | number): ResultType | undefined {
    const pk = this.getPrimaryKey();
    const sql = `SELECT * FROM ${this.tableName} WHERE ${pk} = ?`;
    return this.db.prepare(sql).get(id) as ResultType | undefined;
  }

  private getPrimaryKey(): string {
    const pk = Object.entries(this.table.schema).find(
      ([_, def]) => def.primaryKey
    );
    return pk ? pk[0] : "id";
  }
}
