export interface SqliteTypeMap {
  INTEGER: number;
  TEXT: string;
  REAL: number;
  BOOLEAN: boolean;
}

export interface ColumnDefinition<T extends keyof SqliteTypeMap> {
  sqlType: T;
  primaryKey?: boolean;
  nullable?: boolean;
  references?: string;
}

export type TableSchema = Record<string, ColumnDefinition<keyof SqliteTypeMap>>;

export type Infer<S extends TableSchema> = {
  [K in keyof S]: S[K]["nullable"] extends true ?
    SqliteTypeMap[S[K]["sqlType"]] | null
  : SqliteTypeMap[S[K]["sqlType"]];
};

export const col = <T extends keyof SqliteTypeMap>(
  sqlType: T,
  opts: Omit<ColumnDefinition<T>, "sqlType"> = {}
): ColumnDefinition<T> => ({ sqlType, ...opts });

export class Table<S extends TableSchema = TableSchema> {
  constructor(
    public tableName: string,
    public schema: S
  ) {}

  getCreateSql(): string {
    const cols = Object.entries(this.schema).map(([name, def]) => {
      let str = `${name} ${def.sqlType}`;
      if (def.primaryKey) str += " PRIMARY KEY AUTOINCREMENT";
      if (!def.nullable && !def.primaryKey) str += " NOT NULL";
      if (def.references) str += ` REFERENCES ${def.references}`;
      return str;
    });
    return `CREATE TABLE IF NOT EXISTS ${this.tableName} (${cols.join(", ")});`;
  }
}
