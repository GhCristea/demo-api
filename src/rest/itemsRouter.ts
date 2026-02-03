import { Router } from "express";
import { Item } from "../entities/Item.ts";
import { z } from "../lib/z.ts";
import { getSchema } from "../orm/schemaFactory.ts";
import { ItemService } from "../services/ItemService.ts";

const IdParamSchema = z.string().min(1).coerceNumber();

const ItemQuerySchema = z.object({
  search: z.string().optional(),
  limit: z.string().coerceNumber().optional()
});

export const itemsRouter = Router();
const service = new ItemService();

itemsRouter.get("/", (req, res, next) => {
  try {
    const params = ItemQuerySchema.parse(req.query);
    const items = service.list(params);
    res.json(items);
  } catch (err) {
    next(err);
  }
});

itemsRouter.get("/:id", (req, res, next) => {
  try {
    const id = IdParamSchema.parse(req.params.id);
    const item = service.getOne(id);
    res.json(item);
  } catch (err) {
    next(err);
  }
});

itemsRouter.post("/", (req, res, next) => {
  try {
    const createSchema = getSchema(Item).omit(["id"]);

    if (Array.isArray(req.body)) {
      const items = z.array(createSchema).parse(req.body);
      const results = service.create(items);
      res.status(201).json(results);
    } else {
      const item = createSchema.parse(req.body);
      const result = service.create(item);
      res.status(201).json(result);
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

    const result = service.update(id, body);
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

    const result = service.update(id, body);
    res.json(result);
  } catch (err) {
    next(err);
  }
});

itemsRouter.delete("/:id", (req, res, next) => {
  try {
    const id = IdParamSchema.parse(req.params.id);
    const result = service.delete(id);
    res.json(result);
  } catch (err) {
    next(err);
  }
});
