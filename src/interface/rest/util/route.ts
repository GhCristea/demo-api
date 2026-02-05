import type { Request, Response, NextFunction } from "express";
import type { ZodType, ZodAny, z } from "zod";

type ToSchema<T> = T extends ZodType ? z.infer<T> : ZodAny;
type TypedRequest<P, Q, B> = Request<
  ToSchema<P>,
  ZodAny,
  ToSchema<B>,
  ToSchema<Q>
>;

export const route = <P extends ZodType, Q extends ZodType, B extends ZodType>(
  schemas: { params?: P; query?: Q; body?: B },
  handler: (req: TypedRequest<P, Q, B>, res: Response) => Promise<void> | void
) => {
  return async (req: Request, res: Response, next: NextFunction) => {
    try {
      if (schemas.params) {
        const params = await schemas.params.parseAsync(req.params);
        Object.defineProperty(req, "params", {
          value: params,
          configurable: true
        });
      }
      if (schemas.query) {
        const query = await schemas.query.parseAsync(req.query);
        Object.defineProperty(req, "query", {
          value: query,
          configurable: true
        });
      }
      if (schemas.body) {
        const body = await schemas.body.parseAsync(req.body);
        Object.defineProperty(req, "body", { value: body, configurable: true });
      }

      await handler(req as TypedRequest<P, Q, B>, res);
    } catch (error) {
      next(error);
    }
  };
};
