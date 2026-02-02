import { z } from "../lib/z.ts";
import { getValidationRules } from "./decorators.ts";
import type { BaseEntity, Constructor } from "./types.ts";

export function getSchema<T extends BaseEntity>(Entity: Constructor<T>) {
  const rules = getValidationRules(Entity);

  const schema = z.object(rules);

  return schema;
}
