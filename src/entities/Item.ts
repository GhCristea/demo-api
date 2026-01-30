import { Entity, Column, PrimaryGeneratedColumn } from "../orm/decorators.ts";

@Entity("items")
export class Item {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column()
  name!: string;
}
