// Item entity type
// This is the Source of Truth for item data structure
// Used across: API responses, database queries, validation schemas

type t = {
  id: int,
  name: string,
  description: option<string>,
  createdAt: float,
  updatedAt: float,
}

type createInput = {
  name: string,
  description: option<string>,
}

type updateInput = {
  name: option<string>,
  description: option<string>,
}
