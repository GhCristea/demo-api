import { Router } from "express";
import { AppDataSource } from "../data-source/index.ts";
import { Item } from "../entities/Item.ts";

export const itemsRouter = Router();

itemsRouter.get("/", async (_, res) => {
  try {
    const items = AppDataSource.getRepository(Item).findAll();
    res.json(items);
  } catch (error) {
    res.status(500).json({ error: String(error) });
  }
});

itemsRouter.get("/:id", async (req, res) => {
  try {
    const item = AppDataSource.getRepository(Item).findById(req.params.id);
    if (item) {
      res.json(item);
    } else {
      res.status(404).send("Item not found");
    }
  } catch (error) {
    res.status(500).json({ error: String(error) });
  }
});

itemsRouter.post("/", async (req, res) => {
  const repo = AppDataSource.getRepository(Item);
  const body = req.body;
  try {
    if (Array.isArray(body)) {
      const results = body.map((item) => repo.create(item));
      res.json(results);
    } else {
      const result = repo.create(body);
      res.json(result);
    }
  } catch (error) {
    res.status(500).json({ error: String(error) });
  }
});

itemsRouter.put("/:id", async (req, res) => {
  const repo = AppDataSource.getRepository(Item);
  try {
    const result = repo.update(req.params.id, req.body);
    res.json(result);
  } catch (error) {
    res.status(500).json({ error: String(error) });
  }
});

itemsRouter.put("/", async (req, res) => {
  const repo = AppDataSource.getRepository(Item);
  const body = req.body;
  try {
    if (Array.isArray(body)) {
      const results = body.map((item) => {
        const { id, ...updates } = item;
        return repo.update(id, updates);
      });
      res.json(results);
    } else {
      res.status(400).send("Expected array for bulk update");
    }
  } catch (error) {
    res.status(500).json({ error: String(error) });
  }
});

itemsRouter.delete("/:id", async (req, res) => {
  const repo = AppDataSource.getRepository(Item);
  try {
    const result = repo.delete(req.params.id);
    res.json(result);
  } catch (error) {
    res.status(500).json({ error: String(error) });
  }
});

itemsRouter.delete("/", async (req, res) => {
  const repo = AppDataSource.getRepository(Item);
  const body = req.body;
  try {
    if (Array.isArray(body)) {
      const results = body.map((item) => repo.delete(item.id));
      res.json(results);
    } else {
      res.status(400).send("Expected array for bulk delete");
    }
  } catch (error) {
    res.status(500).json({ error: String(error) });
  }
});
