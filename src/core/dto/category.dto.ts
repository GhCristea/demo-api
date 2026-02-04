import { z } from "zod";

export const CategoryRules = {
  name: z.string().min(3, "Category name must be 3+ chars")
};

export const CreateCategorySchema = z.object(CategoryRules);

export const CategorySchema = z.object({
  id: z.number(),
  ...CategoryRules
});

export type CreateCategoryDTO = z.infer<typeof CreateCategorySchema>;
export type CategoryDTO = z.infer<typeof CategorySchema>;
