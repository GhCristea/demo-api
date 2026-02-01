import { Router } from "express";
import { AppDataSource } from "../data-source/index.ts";
import { Item } from "../entities/Item.ts";
import { BadRequestError, NotFoundError } from "../errors/HttpError.ts";

const parseId = (id: string): number => {
  const parsed = Number(id);
  if (isNaN(parsed) || !Number.isInteger(parsed)) {
    throw new BadRequestError("Invalid ID format");
  }
  return parsed;
};

const isObject = (value: unknown): value is object => {
  return typeof value === "object" && value !== null;
};

const isString = (value: unknown): value is string => {
  return typeof value === "string";
};

const parseObject = (value: unknown): object => {
  if (!isObject(value)) {
    throw new BadRequestError();
  }
  return value;
};

export const itemsRouter = Router();

itemsRouter.get("/", (req, res, next) => {
  try {
    const repo = AppDataSource.getRepository(Item);
    const { search, limit } = req.query;

    let query = repo.getQuery();

    if (isString(search)) {
      query = query.where((f) => f.contains("name", search));
    }

    query = query.limit((isString(limit) && Number(limit)) || 100);

    const items = query.getMany();
    res.json(items);
  } catch (err) {
    next(err);
  }
});

itemsRouter.get("/:id", (req, res, next) => {
  try {
    const id = parseId(req.params.id);
    const item = AppDataSource.getRepository(Item).findById(id);
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
    const body = parseObject(req.body);
    const repo = AppDataSource.getRepository(Item);

    if (Array.isArray(body)) {
      const results = AppDataSource.transaction(() => {
        return body.map((item) => {
          const res = repo.create(parseObject(item));
          return repo.findById(res.lastInsertRowid);
        });
      });
      res.status(201).json(results);
    } else {
      const result = repo.create(parseObject(body));
      const newItem = repo.findById(result.lastInsertRowid);
      res.status(201).json(newItem);
    }
  } catch (err) {
    next(err);
  }
});

itemsRouter.put("/:id", (req, res, next) => {
  try {
    const body = parseObject(req.body);
    const result = AppDataSource.getRepository(Item).update(
      req.params.id,
      body
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
