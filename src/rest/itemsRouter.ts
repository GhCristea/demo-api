import { Router } from "express";
import { AppDataSource } from "../data-source/index.ts";
import { Item } from "../entities/Item.ts";
import { NotFoundError } from "../errors/HttpError.ts";

export const itemsRouter = Router();

itemsRouter.get("/", (_req, res, next) => {
  try {
    const items = AppDataSource.getRepository(Item).findAll();
    res.json(items);
  } catch (err) {
    next(err);
  }
});

itemsRouter.get("/:id", (req, res, next) => {
  try {
    const item = AppDataSource.getRepository(Item).findById(req.params.id);
    if (!item) {
      throw new NotFoundError(`Item with id ${req.params.id} not found`);
    }
    res.json(item);
  } catch (err) {
    next(err);
  }
});

itemsRouter.post("/", (req, res, next) => {
  try {
    const repo = AppDataSource.getRepository(Item);
    const body = req.body;

    if (Array.isArray(body)) {
      const results = body.map((item) => repo.create(item));
      res.status(201).json(results);
    } else {
      const result = repo.create(body);
      res.status(201).json(result);
    }
  } catch (err) {
    next(err);
  }
});

itemsRouter.put("/:id", (req, res, next) => {
  try {
    const result = AppDataSource.getRepository(Item).update(
      req.params.id,
      req.body
    );
    if (result.changes === 0) {
      throw new NotFoundError();
    }
    res.json(result);
  } catch (err) {
    next(err);
  }
});

itemsRouter.delete("/:id", (req, res, next) => {
  try {
    const result = AppDataSource.getRepository(Item).delete(req.params.id);
    if (result.changes === 0) {
      throw new NotFoundError();
    }
    res.json(result);
  } catch (err) {
    next(err);
  }
});
