// Single source of truth for all domain row and input types
// Schema.Items / Schema.Categories — imported by repos, services, controllers

module Items = {
  // Raw SQLite row shape — object syntax matches Bun.Sqlite output
  type row = {
    "id":          int,
    "name":        string,
    "description": Js.Nullable.t<string>,
    "categoryId":  int,
    "createdAt":   float,
    "updatedAt":   float,
  }

  // POST /rest/items
  type insertRow = {
    name:        string,
    description: option<string>,
    categoryId:  int,
  }

  // PUT /rest/items/:id — full replace, id required
  type replaceRow = {
    id:          int,
    name:        string,
    description: option<string>,
    categoryId:  int,
  }

  // PATCH /rest/items/:id — all fields optional
  type patchRow = {
    name:        option<string>,
    description: option<string>,
    categoryId:  option<int>,
  }

  // GET /rest/items query params
  type listParams = {
    search: option<string>,
    limit:  option<int>,
  }
}

module Categories = {
  type row = {
    "id":          int,
    "name":        string,
    "description": Js.Nullable.t<string>,
    "createdAt":   float,
    "updatedAt":   float,
  }

  type insertRow = {
    name:        string,
    description: option<string>,
  }

  type replaceRow = {
    id:          int,
    name:        string,
    description: option<string>,
  }

  type patchRow = {
    name:        option<string>,
    description: option<string>,
  }
}
