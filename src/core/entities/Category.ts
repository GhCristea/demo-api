import {
  Entity,
  Column,
  PrimaryGeneratedColumn
} from "../../orm/decorators.ts";
import { CategoryRules } from "../dto/category.dto.ts";

@Entity("categories")
export class Category {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column({ rule: CategoryRules.name })
  name!: string;
}
