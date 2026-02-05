import { Router } from "express";
import { z } from "zod";
import { CreateItemSchema } from "../../core/dto/item.dto.ts";
import { ItemService } from "../../core/services/ItemService.ts";
import { route } from "./util/route.ts";

export const itemsRouter = Router();
const service = new ItemService();

const IdParams = z.object({ id: z.coerce.number().min(1) });

const ListQuery = z.object({
  search: z.string().optional(),
  limit: z.coerce.number().optional()
});

const BulkCreate = z.union([CreateItemSchema, z.array(CreateItemSchema)]);
const UpdateBody = CreateItemSchema.partial();

itemsRouter.get(
  "/",
  route({ query: ListQuery }, (req, res) => {
    const items = service.list(req.query);
    res.json(items);
  })
);

itemsRouter.get(
  "/:id",
  route({ params: IdParams }, (req, res) => {
    const item = service.getOne(req.params.id);
    res.json(item);
  })
);

itemsRouter.post(
  "/",
  route({ body: BulkCreate }, (req, res) => {
    const result = service.create(req.body);
    res.status(201).json(result);
  })
);

itemsRouter.put(
  "/:id",
  route({ params: IdParams, body: CreateItemSchema }, (req, res) => {
    const result = service.update(req.params.id, req.body);
    res.json(result);
  })
);

itemsRouter.patch(
  "/:id",
  route({ params: IdParams, body: UpdateBody }, (req, res) => {
    const result = service.update(req.params.id, req.body);
    res.json(result);
  })
);

itemsRouter.delete(
  "/:id",
  route({ params: IdParams }, (req, res) => {
    const result = service.delete(req.params.id);
    res.json(result);
  })
);
