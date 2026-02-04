import path from "path";
import { fileURLToPath } from "url";
import { existsSync, mkdirSync } from "fs";
import { DataSource } from "../orm/index.ts";
import { Item } from "../core/entities/Item.ts";
import { Category } from "../core/entities/Category.ts";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const dbPath = path.join(__dirname, "../../", "./data/database.db");
const dbDir = path.dirname(dbPath);

if (!existsSync(dbDir)) {
  mkdirSync(dbDir, { recursive: true });
}

export const AppDataSource = new DataSource({
  dbPath: dbPath,
  entities: [Item, Category],
  logging: process.env.NODE_ENV === "development"
});
