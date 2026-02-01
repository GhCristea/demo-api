export class HttpError extends Error {
  constructor(
    public statusCode: number,
    message: string
  ) {
    super(message);
    this.name = "HttpError";
  }
}

export class NotFoundError extends HttpError {
  constructor(message = "Resource not found") {
    super(404, message);
  }
}

export class BadRequestError extends HttpError {
  constructor(message = "Bad Request") {
    super(400, message);
  }
}

export class ValidationError extends BadRequestError {
  constructor(public errors: string[]) {
    super("Validation Failed");
    this.name = "ValidationError";
  }
}
