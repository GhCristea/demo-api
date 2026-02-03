import type { SQLiteDB } from "./types.ts";
import { Filter, type Field, type FilterCondition } from "./Filter.ts";

export class QueryBuilder<T> {
  private whereClause = "";
  private limitVal = -1;
  private offsetVal = 0;
  private orderByClause = "";
  private joins: string[] = [];
  private selectClause = "";

  constructor(
    private db: SQLiteDB,
    private tableName: string,
    private mapper: (row: unknown) => T
  ) {
    this.selectClause = `${tableName}.*`;
  }

  leftJoin(table: string, on: string) {
    this.joins.push(`LEFT JOIN ${table} ON ${on}`);
    return this;
  }

  select(rawSql: string) {
    this.selectClause = rawSql;
    return this;
  }

  where(callback: (f: Filter<T>) => FilterCondition) {
    const filter = new Filter<T>();
    this.whereClause = callback(filter);
    return this;
  }

  orderBy(field: Field<T>, direction: "ASC" | "DESC" = "ASC") {
    this.orderByClause = `ORDER BY ${this.tableName}.${field} ${direction}`;
    return this;
  }

  limit(count: number) {
    this.limitVal = count;
    return this;
  }

  offset(count: number) {
    this.offsetVal = count;
    return this;
  }

  getSql() {
    const clauses = [
      `SELECT ${this.selectClause} FROM ${this.tableName}`,
      ...this.joins,
      this.whereClause ? `WHERE ${this.whereClause}` : "",
      this.orderByClause,
      this.limitVal > -1 ? `LIMIT ${String(this.limitVal)}` : "",
      this.offsetVal > 0 ? `OFFSET ${String(this.offsetVal)}` : ""
    ];

    return clauses.filter(Boolean).join(" ");
  }

  getMany(): T[] {
    const sql = this.getSql();
    const rows = this.db.prepare(sql).all();
    return rows.map(this.mapper);
  }

  getOne(): T | undefined {
    const sql = this.getSql();
    const row = this.db.prepare(sql).get();
    return row ? this.mapper(row) : undefined;
  }
}
