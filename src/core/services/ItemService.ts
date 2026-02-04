import { AppDataSource } from "../../data-source/index.ts";
import { Item } from "../entities/Item.ts";
import { NotFoundError } from "../errors/AppError.ts";
import type { CreateItemDTO } from "../dto/item.dto.ts";

export class ItemService {
  private repo = AppDataSource.getRepository(Item);

  list(params: { search?: string; limit?: number }) {
    let query = this.repo.getQuery();

    query = query
      .select("items.*, categories.name as categoryName")
      .leftJoin("categories", "items.categoryId = categories.id");

    const search = params.search;
    if (search) {
      query = query.where((f) => f.contains("items.name", search));
    }

    query =
      params.limit && !isNaN(params.limit) ? query.limit(params.limit) : query;
    return query.getMany();
  }

  getOne(id: Item["id"]) {
    const item = this.repo.findById(id);
    if (!item) {
      throw new NotFoundError("Item", id);
    }
    return item;
  }

  create(data: CreateItemDTO | CreateItemDTO[]) {
    if (Array.isArray(data)) {
      return AppDataSource.transaction<Item>(() => {
        return data.map((item) => {
          const res = this.repo.create(item);
          return this.repo.findById(Number(res.lastInsertRowid));
        });
      });
    }

    const res = this.repo.create(data);
    return this.repo.findById(Number(res.lastInsertRowid));
  }

  update(id: Item["id"], data: Partial<CreateItemDTO>) {
    const res = this.repo.update(id, data);
    if (res.changes === 0) {
      throw new NotFoundError("Item", id);
    }
    return res;
  }

  delete(id: Item["id"]) {
    const res = this.repo.delete(id);
    if (res.changes === 0) {
      throw new NotFoundError("Item", id);
    }
    return res;
  }
}
