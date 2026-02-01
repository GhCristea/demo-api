export type FilterCondition = string & { __brand: "FilterCondition" };

export type Field<T> = Extract<keyof T, string>;

export class Filter<T> {
  and(...conditions: FilterCondition[]) {
    return conditions.join(" AND ") as FilterCondition;
  }

  or(...conditions: FilterCondition[]) {
    return `(${conditions.join(" OR ")})` as FilterCondition;
  }

  eq(field: Field<T>, value: string | number) {
    return `${field} = ${this.quote(value)}` as FilterCondition;
  }

  neq(field: Field<T>, value: string | number) {
    return `${field} != ${this.quote(value)}` as FilterCondition;
  }

  contains(field: Field<T>, value: string) {
    return `${field} LIKE '%${this.escape(value)}%'` as FilterCondition;
  }

  startsWith(field: Field<T>, value: string) {
    return `${field} LIKE '${this.escape(value)}%'` as FilterCondition;
  }

  gt(field: Field<T>, value: number) {
    return `${field} > ${String(value)}` as FilterCondition;
  }

  lt(field: Field<T>, value: number) {
    return `${field} < ${String(value)}` as FilterCondition;
  }

  private escape(value: string): string {
    return value.replace(/'/g, "''").replace(/%/g, "\\%").replace(/_/g, "\\_");
  }

  private quote(value: string | number): string {
    return typeof value === "string" ?
        `'${this.escape(value)}'`
      : String(value);
  }
}
