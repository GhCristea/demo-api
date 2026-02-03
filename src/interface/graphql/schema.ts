/**
 * GraphQL Schema Definition.
 *
 * Defines the shape of the GraphQL API.
 * Mirrors Item and Category DTOs for consistency with REST API validation.
 *
 * Key Design:
 * - Queries: Read operations (SELECT)
 * - Mutations: Write operations (INSERT, UPDATE, DELETE)
 * - Inputs: Structured data for mutations (mirrors Zod schemas)
 */

export const typeDefs = `#graphql
  """
  A Category in the catalog.
  """
  type Category {
    id: Int!
    name: String!
    description: String
    createdAt: String!
    updatedAt: String!
  }

  """
  An Item in the catalog.
  """
  type Item {
    id: Int!
    name: String!
    description: String
    categoryId: Int!
    category: Category
    price: Float!
    createdAt: String!
    updatedAt: String!
  }

  """
  Root Query type.
  All read operations are defined here.
  """
  type Query {
    """
    List all items with optional search and limit.
    """
    items(
      search: String
      limit: Int = 100
    ): [Item!]!

    """
    Get a single item by ID.
    Returns null if not found.
    """
    item(id: Int!): Item

    """
    Find items by category ID.
    """
    itemsByCategory(
      categoryId: Int!
      limit: Int = 100
    ): [Item!]!

    """
    Find items within a price range.
    """
    itemsByPrice(
      minPrice: Float!
      maxPrice: Float!
      limit: Int = 100
    ): [Item!]!

    """
    Get all categories sorted by name.
    """
    categories: [Category!]!

    """
    Get a single category by ID.
    Returns null if not found.
    """
    category(id: Int!): Category

    """
    Search categories by name (partial match).
    """
    searchCategories(query: String!): [Category!]!
  }

  """
  Input type for creating a new item.
  Validation rules match Zod schemas in ItemService.
  """
  input CreateItemInput {
    """
    Item name (required, 1-255 characters).
    """
    name: String!

    """
    Item description (optional).
    """
    description: String

    """
    Category ID (required, must reference existing category).
    """
    categoryId: Int!

    """
    Item price (required, must be > 0).
    """
    price: Float!
  }

  """
  Input type for updating an existing item.
  All fields are optional.
  """
  input UpdateItemInput {
    name: String
    description: String
    categoryId: Int
    price: Float
  }

  """
  Input type for creating a new category.
  """
  input CreateCategoryInput {
    name: String!
    description: String
  }

  """
  Input type for updating an existing category.
  """
  input UpdateCategoryInput {
    name: String
    description: String
  }

  """
  Root Mutation type.
  All write operations are defined here.
  """
  type Mutation {
    """
    Create a new item.
    Validation happens automatically via Zod schema in ItemService.
    """
    createItem(input: CreateItemInput!): Item!

    """
    Create multiple items in a single batch.
    Returns array of created items.
    """
    createItems(input: [CreateItemInput!]!): [Item!]!

    """
    Update an existing item by ID.
    Returns the updated item or null if not found.
    """
    updateItem(
      id: Int!
      input: UpdateItemInput!
    ): Item

    """
    Delete an item by ID.
    Returns the deleted item or null if not found.
    """
    deleteItem(id: Int!): Item

    """
    Delete multiple items by their IDs.
    """
    deleteItems(ids: [Int!]!): [Item!]!

    """
    Create a new category.
    """
    createCategory(input: CreateCategoryInput!): Category!

    """
    Update an existing category by ID.
    """
    updateCategory(
      id: Int!
      input: UpdateCategoryInput!
    ): Category

    """
    Delete a category by ID.
    Returns the deleted category or null if not found.
    """
    deleteCategory(id: Int!): Category
  }
`;
