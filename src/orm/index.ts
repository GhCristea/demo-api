import Db from "better-sqlite3";
import type { BaseEntity, EntityClass, SQLiteDB } from "./types.ts";
import { Repository } from "./Repository.ts";
import { getColumnMetadata, getTableName } from "./decorators.ts";

interface Config {
  dbPath: string;
  entities: EntityClass[];
  logging?: boolean;
}

export class DataSource {
  public db: SQLiteDB;
  private entities: EntityClass[];
  private repositories = new Map<EntityClass, Repository>();

  constructor(config: Config) {
    this.db = new Db(config.dbPath, {
      verbose: config.logging ? console.log : undefined
    });
    this.entities = config.entities;

    this.entities.forEach((entity) => {
      if (!getTableName(entity)) {
        throw new Error(`Class ${entity.name} is missing @Entity decorator.`);
      }
    });
  }

  public initialize() {
    return new Promise<void>((resolve) => {
      this.entities.forEach((entity) => {
        const tableName = getTableName(entity);
        const columns = getColumnMetadata(entity);

        if (columns.length === 0 || !tableName) {
          throw new Error(`Entity ${entity.name} has no columns defined.`);
        }

        const colDefs = columns.map((col) => {
          let def = `${col.propertyKey} ${col.type}`;
          if (col.isPrimary) def += " PRIMARY KEY AUTOINCREMENT";
          return def;
        });

        const sql = `CREATE TABLE IF NOT EXISTS ${tableName} (${colDefs.join(", ")})`;

        console.log(`[ORM] Syncing: ${tableName}`);
        this.db.exec(sql);
      });
      resolve();
    });
  }

  public transaction<T>(fn: () => T): T {
    const txn = this.db.transaction(fn);
    return txn();
  }

  public destroy() {
    console.log("[ORM] Closing database connection...");
    this.db.close();
  }

  getRepository<T extends BaseEntity>(entityClass: EntityClass<T>) {
    if (!this.repositories.has(entityClass)) {
      if (!this.entities.includes(entityClass)) {
        throw new Error(`${entityClass.name} not registered in DataSource.`);
      }
      this.repositories.set(
        entityClass,
        new Repository<T>(this.db, entityClass)
      );
    }
    return this.repositories.get(entityClass) as Repository<T>;
  }
}
