import express from "express";
import cors from "cors";
import { itemsRouter } from "./rest/itemsRouter.ts";
import { AppDataSource } from "./data-source/index.ts";
import { errorHandler } from "./middleware/errorHandler.ts";

const app = express();
const PORT = process.env.PORT ?? 3001;

app.use(cors());
app.use(express.json());
app.use("/rest/items", itemsRouter);
app.use(errorHandler);

AppDataSource.initialize()
  .then(() => {
    app.listen(PORT, () => {
      console.log(`Server running on port ${String(PORT)}`);
    });
  })
  .catch((err: unknown) => {
    console.error("Error during Data Source initialization", err);
    process.exit(1);
  });
