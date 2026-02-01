import express from "express";
import cors from "cors";
import { itemsRouter } from "./rest/itemsRouter.ts";
import { AppDataSource } from "./data-source/index.ts";
import { errorHandler } from "./middleware/errorHandler.ts";
import type { Server } from "http";

const app = express();
const PORT = process.env.PORT ?? 3001;

app.use(cors());
app.use(express.json());
app.use("/rest/items", itemsRouter);
app.use(errorHandler);

let server: Server | undefined;

AppDataSource.initialize()
  .then(() => {
    server = app.listen(PORT, () => {
      console.log(`Server running on port ${String(PORT)}`);
    });
  })
  .catch((err: unknown) => {
    console.error("Error during Data Source initialization", err);
    process.exit(1);
  });

const shutdown = () => {
  console.log("\n[Server] Shutting down...");
  if (server) {
    server.close(() => {
      AppDataSource.destroy();
      process.exit(0);
    });
  } else {
    AppDataSource.destroy();
    process.exit(0);
  }
};

process.on("SIGINT", shutdown);
process.on("SIGTERM", shutdown);
