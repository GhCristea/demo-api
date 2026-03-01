// Item business logic with Dependency Injection
// Deps are injected to allow testing without database

// ========================================================================
// Dependencies Interface
// ========================================================================

type deps = {
  list: unit => promise<result<array<Item.t>, AppError.t>>,
  get: int => promise<result<Item.t, AppError.t>>,
  create: Item.createInput => promise<result<Item.t, AppError.t>>,
  update: (int, Item.updateInput) => promise<result<Item.t, AppError.t>>,
  delete: int => promise<result<unit, AppError.t>>,
}

// ========================================================================
// Mock/Default Implementation (for testing)
// ========================================================================

let mockList = async (): promise<result<array<Item.t>, AppError.t>> => {
  Ok([])->Promise.resolve
}

let mockGet = async (_id: int): promise<result<Item.t, AppError.t>> => {
  Error(AppError.NotFound("Item not found"))->Promise.resolve
}

let mockCreate = async (_input: Item.createInput): promise<result<Item.t, AppError.t>> => {
  Error(AppError.Internal("Not implemented"))->Promise.resolve
}

let mockUpdate = async (_id: int, _input: Item.updateInput): promise<result<Item.t, AppError.t>> => {
  Error(AppError.Internal("Not implemented"))->Promise.resolve
}

let mockDelete = async (_id: int): promise<result<unit, AppError.t>> => {
  Error(AppError.Internal("Not implemented"))->Promise.resolve
}

// ========================================================================
// Default Service Instance (with actual database)
// ========================================================================

let default: deps = {
  list: mockList,
  get: mockGet,
  create: mockCreate,
  update: mockUpdate,
  delete: mockDelete,
}
