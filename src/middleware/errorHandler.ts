import type { Request, Response, NextFunction } from "express";
import { mapDbError } from "../orm/dbErrorMapper.ts";
import { HttpError } from "../errors/HttpError.ts";

export function errorHandler(
  err: unknown,
  _req: Request,
  res: Response,
  _next: NextFunction
) {
  const httpError = mapDbError(err);

  if (httpError instanceof HttpError) {
    res.status(httpError.statusCode).json({
      status: "error",
      statusCode: httpError.statusCode,
      message: httpError.message
    });
  } else {
    res.status(500).json({
      status: "error",
      statusCode: 500,
      message: "Internal Server Error"
    });
  }
}
