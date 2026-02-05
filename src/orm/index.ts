import Db from "better-sqlite3";
import type { BaseEntity, SQLiteDB } from "./types.ts";
import type { Table, TableSchema, Infer } from "./dialect.ts";
import { QueryBuilder } from "./QueryBuilder.ts";

interface Config {
  dbPath: string;
  tables?: Table[];
  logging?: boolean;
}

export class DataSource {
  public db: SQLiteDB;
  private tables: Table[];

  constructor(config: Config) {
    this.db = new Db(config.dbPath, {
      verbose: config.logging ? console.log : undefined
    });
    this.tables = config.tables ?? [];

    this.db.pragma("journal_mode = WAL");
    this.db.pragma("foreign_keys = ON");
    this.db.pragma("synchronous = NORMAL");
  }

  public initialize() {
    return new Promise<void>((resolve) => {
      this.tables.forEach((table) => {
        this.syncTable(table.tableName, table.getCreateSql());
      });
      resolve();
    });
  }

  private syncTable(name: string, sql: string) {
    console.log(`[ORM] Syncing: ${name}`);
    this.db.exec(sql);
  }

  public transaction<T extends BaseEntity>(
    fn: () => (T | undefined)[]
  ): (T | undefined)[] {
    const txn = this.db.transaction(fn);
    return txn();
  }

  public destroy() {
    console.log("[ORM] Closing database connection...");
    this.db.close();
  }

  table<S extends TableSchema>(table: Table<S>): QueryBuilder<Infer<S>> {
    return new QueryBuilder<Infer<S>>(this.db, table);
  }
}
