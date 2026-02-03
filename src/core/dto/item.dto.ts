import { z } from "zod";

export const ItemRules = {
  name: z.string().min(3, "Name must be 3+ chars").max(50),
  categoryId: z.number().optional()
};

export const CreateItemSchema = z.object(ItemRules);

export const ItemSchema = z.object({
  id: z.number(),
  ...ItemRules
});

export type CreateItemDTO = z.infer<typeof CreateItemSchema>;
export type ItemDTO = z.infer<typeof ItemSchema>;
