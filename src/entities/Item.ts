import { Entity, Column, PrimaryGeneratedColumn } from "../orm/decorators.ts";
import { IsNotEmpty, MinLength } from "../orm/validation.ts";

@Entity("items")
export class Item {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column()
  @IsNotEmpty()
  @MinLength(3)
  name!: string;
}
