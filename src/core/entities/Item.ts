import {
  Entity,
  Column,
  PrimaryGeneratedColumn
} from "../../orm/decorators.ts";
import { ItemRules } from "../dto/item.dto.ts";

@Entity("items")
export class Item {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column({ rule: ItemRules.name })
  name!: string;

  @Column({
    rule: ItemRules.categoryId,
    foreignKey: "categories.id"
  })
  categoryId!: number;

  categoryName?: string;
}
