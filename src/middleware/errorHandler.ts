import type { Request, Response, NextFunction } from "express";
import { mapDbError } from "../orm/dbErrorMapper.ts";
import { HttpError, ValidationError } from "../errors/HttpError.ts";
import { ZError } from "../lib/z.ts";

export function errorHandler(
  err: unknown,
  _req: Request,
  res: Response,
  _next: NextFunction
) {
  if (err instanceof ZError) {
    res.status(400).json({
      status: "error",
      statusCode: 400,
      message: "Validation Failed",
      timestamp: new Date().toISOString(),
      path: _req.url,
      errors: err.issues.map((issue) => ({
        path:
          issue.path
            ?.map((k) => (typeof k === "object" ? k.key : k))
            .join(".") ?? "root",
        message: issue.message
      }))
    });
    return;
  }

  if (err instanceof ValidationError) {
    res.status(400).json({
      status: "error",
      statusCode: 400,
      message: "Validation Failed",
      errors: err.errors,
      timestamp: new Date().toISOString(),
      path: _req.url
    });
    return;
  }

  const httpError = mapDbError(err);

  if (httpError instanceof HttpError) {
    res.status(httpError.statusCode).json({
      status: "error",
      statusCode: httpError.statusCode,
      message: httpError.message,
      timestamp: new Date().toISOString(),
      path: _req.url
    });
  } else {
    res.status(500).json({
      status: "error",
      statusCode: 500,
      message: "Internal Server Error",
      timestamp: new Date().toISOString(),
      path: _req.url
    });
  }
}
