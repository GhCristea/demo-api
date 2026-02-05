import { z } from "zod";

export const CreateItemSchema = z.object({
  name: z.string().min(3, "Name must be 3+ chars").max(50),
  categoryId: z.coerce.number()
});

export type CreateItemDTO = z.infer<typeof CreateItemSchema>;
