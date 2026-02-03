import type { Request, Response, NextFunction } from "express";
import { ZodError } from "zod";
import {
  AppError,
  NotFoundError,
  ValidationError
} from "../core/errors/AppError.ts";

export function errorHandler(
  err: unknown,
  _req: Request,
  res: Response,
  _next: NextFunction
) {
  if (err instanceof ZodError) {
    res.status(400).json({
      status: "error",
      statusCode: 400,
      message: "Validation Failed",
      errors: err.issues,
      timestamp: new Date().toISOString(),
      path: _req.url
    });
    return;
  }

  if (err instanceof ValidationError) {
    res.status(400).json({
      status: "error",
      statusCode: 400,
      message: "Validation Failed",
      errors: err.issues,
      timestamp: new Date().toISOString(),
      path: _req.url
    });
    return;
  }

  if (err instanceof NotFoundError) {
    res.status(404).json({
      status: "error",
      statusCode: 404,
      message: err.message,
      timestamp: new Date().toISOString(),
      path: _req.url
    });
    return;
  }

  if (err instanceof AppError) {
    res.status(400).json({
      status: "error",
      statusCode: 400,
      message: err.message,
      timestamp: new Date().toISOString(),
      path: _req.url
    });
    return;
  }

  console.error("Unexpected error:", err);
  res.status(500).json({
    status: "error",
    statusCode: 500,
    message: "Internal Server Error",
    timestamp: new Date().toISOString(),
    path: _req.url
  });
}
