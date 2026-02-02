import type { StandardSchemaV1 } from "@standard-schema/spec";

type Check<T> = (value: T) => void;
type Shape<T extends object = object> = { [K in keyof T]: ZType<T[K]> };

type Issue = StandardSchemaV1.Issue;

export class ZError extends Error {
  constructor(public issues: Issue[]) {
    super("Validation failed");
    this.name = "ZError";
    this._isZError = true;
  }
  _isZError = true;
}

export class ZType<T> implements StandardSchemaV1<unknown, T> {
  constructor(
    protected _parse: (val: unknown) => T,
    protected checks: Check<T>[] = []
  ) {}

  readonly "~standard": StandardSchemaV1.Props<unknown, T> = {
    version: 1,
    vendor: "tiny-zod",
    validate: (value: unknown) => {
      const result = this.safeParse(value);
      if (result.success) {
        return { value: result.data };
      }
      return { issues: result.issues };
    }
  };

  protected addCheck(check: Check<T>) {
    this.checks.push(check);
    return this;
  }

  protected error(message: string, path: (string | number)[] = []): never {
    throw new ZError([{ message, path }]);
  }

  parse(data: unknown): T {
    const result = this.safeParse(data);
    if (!result.success) {
      throw new ZError(result.issues);
    }
    return result.data;
  }

  safeParse(data: unknown) {
    try {
      const result = this._parse(data);
      for (const check of this.checks) {
        check(result);
      }
      return { success: true as const, data: result };
    } catch (err) {
      if (err instanceof ZError) {
        return { success: false as const, issues: err.issues };
      }
      throw err;
    }
  }

  optional() {
    return new ZType<T | undefined>((val) => {
      if (val === undefined || val === null) return undefined;
      const res = this.safeParse(val);
      if (!res.success) throw new ZError(res.issues);
      return res.data;
    });
  }
}

export class ZString extends ZType<string> {
  constructor() {
    super((val) => {
      if (typeof val !== "string") this.error("Expected string");
      return val;
    });
  }

  min(length: number, message?: string) {
    return this.addCheck((val) => {
      if (val.length < length) {
        this.error(message ?? `Must be at least ${String(length)} chars`);
      }
    });
  }

  coerceNumber() {
    return new ZType<number>((val) => {
      const num = Number(val);
      if (isNaN(num)) this.error("Expected number");
      return num;
    });
  }
}

export class ZObject<T extends object> extends ZType<T> {
  constructor(public shape: Shape<T>) {
    super((val) => {
      if (typeof val !== "object" || val === null)
        this.error("Expected object");

      const result = {} as T;
      const issues: Issue[] = [];
      const input = val as Record<string, unknown>;

      for (const key of Object.keys(this.shape)) {
        const schema = this.shape[key as keyof T];
        const check = schema.safeParse(input[key]);

        if (check.success) {
          result[key as keyof T] = check.data;
        } else {
          check.issues.forEach((issue) => {
            issues.push({
              message: issue.message,
              path: [key, ...(issue.path ?? [])]
            });
          });
        }
      }

      if (issues.length > 0) throw new ZError(issues);
      return result;
    });
  }

  pick<K extends keyof T>(keys: K[]) {
    const newShape = {} as Shape<Pick<T, K>>;
    keys.forEach((k) => (newShape[k] = this.shape[k]));
    return new ZObject(newShape);
  }

  omit<K extends keyof T>(keys: K[]) {
    const newShape = { ...this.shape };
    keys.forEach((k) => {
      // eslint-disable-next-line @typescript-eslint/no-dynamic-delete
      delete newShape[k];
    });
    return new ZObject(newShape as Shape<Omit<T, K>>);
  }

  partial() {
    const newShape: Record<string, ZType<T[keyof T] | undefined>> = {};
    for (const key of Object.keys(this.shape)) {
      newShape[key] = this.shape[key as keyof T].optional();
    }
    return new ZObject(newShape);
  }
}

export class ZArray<T> extends ZType<T[]> {
  constructor(schema: ZType<T>) {
    super((val) => {
      if (!Array.isArray(val)) this.error("Expected array");

      const result: T[] = [];
      const issues: Issue[] = [];

      val.forEach((item, i) => {
        const check = schema.safeParse(item);
        if (check.success) {
          result.push(check.data);
        } else {
          check.issues.forEach((issue) => {
            issues.push({
              message: issue.message,
              path: [i, ...(issue.path ?? [])]
            });
          });
        }
      });

      if (issues.length > 0) throw new ZError(issues);
      return result;
    });
  }
}

export const z = {
  string: () => new ZString(),
  object: <T extends object>(shape: Shape<T>) => new ZObject<T>(shape),
  array: <T>(schema: ZType<T>) => new ZArray<T>(schema)
};
