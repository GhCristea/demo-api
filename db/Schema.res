// Typed shapes derived from Schema_ definitions
// Row types = what SQLite returns
// Insert/Update types = what we send to SQLite
// All types are plain records — no classes, no magic

module Categories = {
  // Returned by SELECT
  type row = {
    "id": int,
    "name": string,
    "description": Js.Nullable.t<string>,
    "createdAt": float,
    "updatedAt": float,
  }

  // Used by INSERT
  type insertRow = {
    name: string,
    description: option<string>,
  }

  // Used by PUT (full replace — updatedAt is set by DB trigger)
  type replaceRow = {
    id: int,
    name: string,
    description: option<string>,
  }
}

module Items = {
  // Returned by SELECT
  type row = {
    "id": int,
    "name": string,
    "description": Js.Nullable.t<string>,
    "categoryId": int,
    "createdAt": float,
    "updatedAt": float,
  }

  // Used by INSERT
  type insertRow = {
    name: string,
    description: option<string>,
    categoryId: int,
  }

  // Used by PUT (full replace — null description = unset)
  type replaceRow = {
    id: int,
    name: string,
    description: option<string>,
    categoryId: int,
  }

  // Used by findAll query params
  type listParams = {
    search: option<string>,
    limit: option<int>,
  }
}
