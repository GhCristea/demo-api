import { Entity, Column, PrimaryGeneratedColumn } from "../orm/decorators.ts";
import { z } from "../lib/z.ts";

@Entity("items")
export class Item {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column({
    rule: z.string().min(3, "Name must be 3+ chars")
  })
  name!: string;
}
