import { Router } from "express";
import { AppDataSource } from "../data-source/index.ts";
import { Item } from "../entities/Item.ts";
import { NotFoundError } from "../errors/HttpError.ts";
import { z } from "../lib/z.ts";
import { getSchema } from "../orm/schemaFactory.ts";

const IdParamSchema = z.string().min(1).coerceNumber();

const ItemQuerySchema = z.object({
  search: z.string().optional(),
  limit: z.string().coerceNumber().optional()
});

export const itemsRouter = Router();

itemsRouter.get("/", (req, res, next) => {
  try {
    const repo = AppDataSource.getRepository(Item);
    const { search, limit } = ItemQuerySchema.parse(req.query);

    let query = repo.getQuery();

    if (search) {
      query = query.where((f) => f.contains("name", search));
    }

    query = query.limit(limit ?? 100);
    res.json(query.getMany());
  } catch (err) {
    next(err);
  }
});

itemsRouter.get("/:id", (req, res, next) => {
  try {
    const id = IdParamSchema.parse(req.params.id);

    const item = AppDataSource.getRepository(Item).findById(id);
    if (!item) {
      throw new NotFoundError(`Item with id ${String(id)} not found`);
    }
    res.json(item);
  } catch (err) {
    next(err);
  }
});

itemsRouter.post("/", (req, res, next) => {
  try {
    const repo = AppDataSource.getRepository(Item);

    const createSchema = getSchema(Item).omit(["id"]);

    if (Array.isArray(req.body)) {
      const items = z.array(createSchema).parse(req.body);

      const results = AppDataSource.transaction(() => {
        return items.map((item) => {
          const res = repo.create(item);
          return repo.findById(Number(res.lastInsertRowid));
        });
      });
      res.status(201).json(results);
    } else {
      const item = createSchema.parse(req.body);

      const result = repo.create(item);
      res.status(201).json(repo.findById(Number(result.lastInsertRowid)));
    }
  } catch (err) {
    next(err);
  }
});

itemsRouter.put("/:id", (req, res, next) => {
  try {
    const id = IdParamSchema.parse(req.params.id);
    const updateSchema = getSchema(Item).omit(["id"]);
    const body = updateSchema.parse(req.body);

    const result = AppDataSource.getRepository(Item).update(id, body);
    if (result.changes === 0) throw new NotFoundError();
    res.json(result);
  } catch (err) {
    next(err);
  }
});

itemsRouter.patch("/:id", (req, res, next) => {
  try {
    const id = IdParamSchema.parse(req.params.id);
    const updateSchema = getSchema(Item).omit(["id"]).partial();
    const body = updateSchema.parse(req.body);

    const result = AppDataSource.getRepository(Item).update(id, body);
    if (result.changes === 0) throw new NotFoundError();
    res.json(result);
  } catch (err) {
    next(err);
  }
});

itemsRouter.delete("/:id", (req, res, next) => {
  try {
    const id = IdParamSchema.parse(req.params.id);
    const result = AppDataSource.getRepository(Item).delete(id);
    if (result.changes === 0) throw new NotFoundError();
    res.json(result);
  } catch (err) {
    next(err);
  }
});
