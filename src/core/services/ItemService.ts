import { AppDataSource } from "../../data-source/index.ts";
import { Items, Categories, TABLE } from "../entities.ts";
import { NotFoundError } from "../errors/AppError.ts";
import type { CreateItemDTO } from "../dto/item.dto.ts";

export class ItemService {
  private get items() {
    return AppDataSource.table(Items);
  }

  list(params: { search?: string; limit?: number }) {
    let query = this.items.selectRaw(
      `${TABLE.Items}.*, ${TABLE.Categories}.name as categoryName`
    );

    query = query.leftJoin(
      Categories,
      `${TABLE.Items}.categoryId = ${TABLE.Categories}.id`
    );

    const search = params.search;
    if (search) {
      query = query.where(`${TABLE.Items}.name`, "LIKE", `%${search}%`);
    }

    if (params.limit && !isNaN(params.limit)) {
      query = query.limit(params.limit);
    }

    return query.get();
  }

  getOne(id: number) {
    const item = this.items.findById(id);
    if (!item) {
      throw new NotFoundError("Item", id);
    }
    return item;
  }

  create(data: CreateItemDTO | CreateItemDTO[]) {
    if (Array.isArray(data)) {
      return AppDataSource.transaction(() => {
        return data.map((item) => {
          const res = this.items.create(item);
          return this.items.findById(Number(res.lastInsertRowid));
        });
      });
    }

    const res = this.items.create(data);
    return this.items.findById(Number(res.lastInsertRowid));
  }

  update(id: number, data: Partial<CreateItemDTO>) {
    const res = this.items.update(id, data);
    if (res.changes === 0) {
      throw new NotFoundError("Item", id);
    }
    return res;
  }

  delete(id: number) {
    const res = this.items.delete(id);
    if (res.changes === 0) {
      throw new NotFoundError("Item", id);
    }
    return res;
  }
}
