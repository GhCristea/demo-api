import { SqliteError } from "better-sqlite3";
import { HttpError } from "../errors/HttpError.ts";

const ERROR_MAP: Record<string, { statusCode: number; message: string }> = {
  SQLITE_CONSTRAINT_UNIQUE: {
    statusCode: 409,
    message: "Resource already exists (Unique Constraint Violation)"
  },
  SQLITE_CONSTRAINT_PRIMARYKEY: {
    statusCode: 409,
    message: "Resource already exists (Unique Constraint Violation)"
  },
  SQLITE_CONSTRAINT_FOREIGNKEY: {
    statusCode: 409,
    message: "Foreign key constraint violation"
  },
  SQLITE_CONSTRAINT_NOTNULL: {
    statusCode: 400,
    message: "Missing required field (Not Null Constraint)"
  },
  SQLITE_MISMATCH: {
    statusCode: 400,
    message: "Data type mismatch"
  }
};

export function mapDbError(error: unknown): Error {
  if (error instanceof HttpError) {
    return error;
  }

  if (error instanceof SqliteError) {
    const mapping = ERROR_MAP[error.code];
    if (mapping) {
      return new HttpError(mapping.statusCode, mapping.message);
    }
    return new HttpError(500, `Database Error: ${error.message}`);
  }

  if (error instanceof Error) {
    return new HttpError(500, error.message);
  }

  return new HttpError(500, "Unknown internal server error");
}
