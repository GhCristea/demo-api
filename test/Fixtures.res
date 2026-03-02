// Shared test domain objects — pure data, no service logic
// Scenario builders compose from *Service.mock() with record spread

let mockItem: Item.t = {
  id:          1,
  name:        "Test Item",
  description: Some("A test description"),
  categoryId:  1,
  createdAt:   1640000000.0,
  updatedAt:   1640000000.0,
}

let mockCategory: Category.t = {
  id:          1,
  name:        "Test Category",
  description: None,
  createdAt:   1640000000.0,
  updatedAt:   1640000000.0,
}

// ─── ItemService scenario builders ──────────────────────────────────────────────────────────

let notFoundItemSvc = (): ItemService.t => {
  ...ItemService.mock(),
  findById: id => Error(AppError.NotFound(`Item ${Int.toString(id)} not found`)),
  replace:  _  => Error(AppError.NotFound("Item not found")),
  delete:   id => Error(AppError.NotFound(`Item ${Int.toString(id)} not found`)),
}

let dbErrorItemSvc = (): ItemService.t => {
  ...ItemService.mock(),
  insert:     _ => Error(AppError.Internal("DB error")),
  insertMany: _ => Error(AppError.Internal("DB error")),
}

let validationErrorItemSvc = (): ItemService.t => {
  ...ItemService.mock(),
  insert: _ => Error(AppError.ValidationError(["name is required"])),
}
