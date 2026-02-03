import { AppDataSource } from "../data-source/index.ts";
import { Item } from "../entities/Item.ts";
import { NotFoundError } from "../errors/HttpError.ts";

export class ItemService {
  private repo = AppDataSource.getRepository(Item);

  list(params: { search: string | undefined; limit: number | undefined }) {
    let query = this.repo.getQuery();

    const { search, limit } = params;
    if (search) {
      query = query.where((f) => f.contains("name", search));
    }

    query = query.limit(limit ?? 100);
    return query.getMany();
  }

  getOne(id: number) {
    const item = this.repo.findById(id);
    if (!item) {
      throw new NotFoundError(`Item ${String(id)} not found`);
    }
    return item;
  }

  create(data: Partial<Item> | Partial<Item>[]) {
    if (Array.isArray(data)) {
      return AppDataSource.transaction(() => {
        return data.map((item) => {
          const res = this.repo.create(item);
          return this.repo.findById(Number(res.lastInsertRowid));
        });
      });
    }

    const res = this.repo.create(data);
    return this.repo.findById(Number(res.lastInsertRowid));
  }

  update(id: number, data: Partial<Item>) {
    const res = this.repo.update(id, data);
    if (res.changes === 0) {
      throw new NotFoundError(`Item ${String(id)} not found`);
    }
    return res;
  }

  delete(id: number) {
    const res = this.repo.delete(id);
    if (res.changes === 0) {
      throw new NotFoundError(`Item ${String(id)} not found`);
    }
    return res;
  }
}
