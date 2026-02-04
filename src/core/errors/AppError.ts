export class AppError extends Error {
  constructor(
    public readonly code: string,
    message: string
  ) {
    super(message);
    this.name = "AppError";
  }
}

export class NotFoundError extends AppError {
  constructor(resource: string, id?: string | number) {
    super(
      "RESOURCE_NOT_FOUND",
      `${resource} ${id ? `with id ${String(id)} ` : ""}not found`
    );
  }
}

export class ValidationError extends AppError {
  constructor(public readonly issues: string[]) {
    super("VALIDATION_ERROR", "Validation failed");
  }
}
