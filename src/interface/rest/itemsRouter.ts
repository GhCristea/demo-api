import { Router } from "express";
import { z } from "zod";
import {
  CreateItemSchema,
  type CreateItemDTO
} from "../../core/dto/item.dto.ts";
import { ItemService } from "../../core/services/ItemService.ts";

const IdParamSchema = z.coerce.number().min(1);

const ItemQuerySchema = z.object({
  search: z.string().optional(),
  limit: z.coerce.number().optional()
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
    if (Array.isArray(req.body)) {
      const items = z.array(CreateItemSchema).parse(req.body);
      const results = service.create(items);
      res.status(201).json(results);
    } else {
      const item = CreateItemSchema.parse(req.body);
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
    const body = CreateItemSchema.parse(req.body);

    const result = service.update(id, body);
    res.json(result);
  } catch (err) {
    next(err);
  }
});

itemsRouter.patch("/:id", (req, res, next) => {
  try {
    const id = IdParamSchema.parse(req.params.id);
    const body = CreateItemSchema.partial().parse(req.body);

    const result = service.update(id, body as CreateItemDTO);
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
