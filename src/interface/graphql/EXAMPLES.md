# GraphQL API - Quick Reference & Examples

## Setup

```bash
# Install dependencies
npm install graphql @apollo/server @apollo/server/express4

# Start server
npm run dev

# Open GraphQL Playground
# http://localhost:3001/graphql
```

---

## Queries (Read Operations)

### Get All Items

```graphql
query {
  items {
    id
    name
    description
    price
    categoryId
    createdAt
  }
}
```

### Get All Items with Limit

```graphql
query {
  items(limit: 5) {
    id
    name
    price
  }
}
```

### Search Items

```graphql
query SearchItems {
  items(search: "laptop") {
    id
    name
    description
    price
  }
}
```

### Get Single Item by ID

```graphql
query GetItem {
  item(id: 1) {
    id
    name
    description
    price
    category {
      id
      name
    }
  }
}
```

### Get Items by Category

```graphql
query GetItemsByCategory {
  itemsByCategory(categoryId: 1, limit: 10) {
    id
    name
    price
  }
}
```

### Get Items by Price Range

```graphql
query GetItemsByPrice {
  itemsByPrice(minPrice: 50, maxPrice: 500) {
    id
    name
    price
  }
}
```

### Get All Categories

```graphql
query GetCategories {
  categories {
    id
    name
    description
  }
}
```

### Get Category by ID

```graphql
query GetCategory {
  category(id: 1) {
    id
    name
    description
  }
}
```

### Search Categories

```graphql
query SearchCategories {
  searchCategories(query: "electron") {
    id
    name
    description
  }
}
```

### Complex Query: Items with Categories

```graphql
query GetItemsWithCategories {
  items(limit: 20) {
    id
    name
    description
    price
    category {
      id
      name
      description
    }
    createdAt
    updatedAt
  }
}
```

---

## Mutations (Write Operations)

### Create Single Item

```graphql
mutation CreateItem {
  createItem(input: {
    name: "Wireless Mouse"
    description: "Ergonomic wireless mouse with 5000 DPI"
    categoryId: 1
    price: 49.99
  }) {
    id
    name
    price
    createdAt
  }
}
```

### Create Multiple Items (Batch)

```graphql
mutation CreateMultipleItems {
  createItems(input: [
    {
      name: "USB-C Hub"
      description: "7-in-1 USB-C Hub"
      categoryId: 1
      price: 39.99
    }
    {
      name: "Mechanical Keyboard"
      description: "RGB Mechanical Keyboard"
      categoryId: 1
      price: 119.99
    }
    {
      name: "Monitor Stand"
      description: "Adjustable Monitor Stand"
      categoryId: 2
      price: 29.99
    }
  ]) {
    id
    name
    price
    category {
      id
      name
    }
  }
}
```

### Update Item

```graphql
mutation UpdateItem {
  updateItem(id: 1, input: {
    name: "Updated Item Name"
    price: 59.99
  }) {
    id
    name
    price
    updatedAt
  }
}
```

### Update Item Price Only

```graphql
mutation UpdatePrice {
  updateItem(id: 1, input: {
    price: 89.99
  }) {
    id
    name
    price
  }
}
```

### Update Item Description

```graphql
mutation UpdateDescription {
  updateItem(id: 1, input: {
    description: "New description for the item"
  }) {
    id
    description
    updatedAt
  }
}
```

### Delete Item

```graphql
mutation DeleteItem {
  deleteItem(id: 1) {
    id
    name
    price
  }
}
```

### Delete Multiple Items

```graphql
mutation DeleteMultipleItems {
  deleteItems(ids: [1, 2, 3]) {
    id
    name
  }
}
```

### Create Category

```graphql
mutation CreateCategory {
  createCategory(input: {
    name: "Electronics"
    description: "Electronic devices and accessories"
  }) {
    id
    name
    description
  }
}
```

### Update Category

```graphql
mutation UpdateCategory {
  updateCategory(id: 1, input: {
    description: "Updated category description"
  }) {
    id
    name
    description
    updatedAt
  }
}
```

### Delete Category

```graphql
mutation DeleteCategory {
  deleteCategory(id: 1) {
    id
    name
  }
}
```

---

## Variables (Parameterized Queries)

### Query with Variables

```graphql
query GetItemsByPriceRange($min: Float!, $max: Float!) {
  itemsByPrice(minPrice: $min, maxPrice: $max) {
    id
    name
    price
  }
}

# Variables (JSON)
{
  "min": 50,
  "max": 200
}
```

### Mutation with Variables

```graphql
mutation CreateNewItem($name: String!, $categoryId: Int!, $price: Float!) {
  createItem(input: {
    name: $name
    categoryId: $categoryId
    price: $price
  }) {
    id
    name
    price
  }
}

# Variables (JSON)
{
  "name": "Gaming Mouse",
  "categoryId": 1,
  "price": 69.99
}
```

### Batch Create with Variables

```graphql
mutation CreateMultiple($items: [CreateItemInput!]!) {
  createItems(input: $items) {
    id
    name
    price
  }
}

# Variables (JSON)
{
  "items": [
    {
      "name": "Item 1",
      "categoryId": 1,
      "price": 10.0
    },
    {
      "name": "Item 2",
      "categoryId": 2,
      "price": 20.0
    }
  ]
}
```

---

## Error Handling Examples

### Validation Error: Short Name

**Request:**

```graphql
mutation {
  createItem(input: {
    name: "A"
    categoryId: 1
    price: 10
  }) {
    id
  }
}
```

**Response:**

```json
{
  "errors": [
    {
      "message": "Validation failed",
      "extensions": {
        "code": "BAD_USER_INPUT",
        "http": { "status": 400 },
        "issues": [
          {
            "path": "name",
            "message": "String must contain at least 2 character(s)"
          }
        ]
      }
    }
  ]
}
```

### Not Found Error

**Request:**

```graphql
query {
  item(id: 99999) {
    id
    name
  }
}
```

**Response:**

```json
{
  "data": {
    "item": null
  }
}
```

### Missing Required Field

**Request:**

```graphql
mutation {
  createItem(input: {
    categoryId: 1
    price: 10
  }) {
    id
  }
}
```

**Response (caught by GraphQL):**

```json
{
  "errors": [
    {
      "message": "Field 'CreateItemInput.name' of required type 'String!' was not provided valid value",
      "extensions": {
        "code": "BAD_USER_INPUT"
      }
    }
  ]
}
```

---

## Aliases (Query Multiple Variations)

### Query Items with Different Price Ranges

```graphql
query {
  budgetItems: itemsByPrice(minPrice: 10, maxPrice: 50) {
    name
    price
  }
  midRangeItems: itemsByPrice(minPrice: 50, maxPrice: 200) {
    name
    price
  }
  premiumItems: itemsByPrice(minPrice: 200, maxPrice: 10000) {
    name
    price
  }
}
```

### Multiple Category Queries

```graphql
query {
  electronics: itemsByCategory(categoryId: 1) {
    id
    name
  }
  furniture: itemsByCategory(categoryId: 2) {
    id
    name
  }
}
```

---

## Fragments (Reusable Selections)

### Define Fragment

```graphql
fragment ItemBasics on Item {
  id
  name
  price
  createdAt
}

fragment ItemFull on Item {
  ...ItemBasics
  description
  categoryId
  category {
    id
    name
  }
}
```

### Use Fragment in Query

```graphql
query {
  items(limit: 5) {
    ...ItemFull
  }
}
```

### Use Fragment in Mutation

```graphql
mutation {
  createItem(input: {
    name: "New Item"
    categoryId: 1
    price: 99.99
  }) {
    ...ItemFull
  }
}
```

---

## Introspection (Schema Exploration)

### Get All Types

```graphql
query {
  __schema {
    types {
      name
      description
    }
  }
}
```

### Get Item Type Details

```graphql
query {
  __type(name: "Item") {
    name
    fields {
      name
      type {
        name
        kind
      }
    }
  }
}
```

### Get Query Type

```graphql
query {
  __type(name: "Query") {
    name
    fields {
      name
      args {
        name
        type {
          name
          kind
        }
      }
    }
  }
}
```

---

## cURL Examples

### Query via cURL

```bash
curl -X POST http://localhost:3001/graphql \
  -H "Content-Type: application/json" \
  -d '{
    "query": "query { items(limit: 5) { id name price } }"
  }'
```

### Mutation via cURL

```bash
curl -X POST http://localhost:3001/graphql \
  -H "Content-Type: application/json" \
  -d '{
    "query": "mutation { createItem(input: {name: \"Test\", categoryId: 1, price: 10}) { id name } }"
  }'
```

### With Variables via cURL

```bash
curl -X POST http://localhost:3001/graphql \
  -H "Content-Type: application/json" \
  -d '{
    "query": "query GetItem($id: Int!) { item(id: $id) { id name } }",
    "variables": { "id": 1 }
  }'
```

---

## Comparison: REST vs GraphQL

### List Items

**REST:**
```bash
GET /rest/items?limit=5
```

**GraphQL:**
```graphql
query {
  items(limit: 5) {
    id
    name
  }
}
```

### Create Item

**REST:**
```bash
POST /rest/items
Body: { "name": "Item", "categoryId": 1, "price": 10 }
```

**GraphQL:**
```graphql
mutation {
  createItem(input: {
    name: "Item"
    categoryId: 1
    price: 10
  }) {
    id
    name
  }
}
```

### Update Item

**REST:**
```bash
PUT /rest/items/1
Body: { "price": 20 }
```

**GraphQL:**
```graphql
mutation {
  updateItem(id: 1, input: { price: 20 }) {
    id
    price
  }
}
```

### Delete Item

**REST:**
```bash
DELETE /rest/items/1
```

**GraphQL:**
```graphql
mutation {
  deleteItem(id: 1) {
    id
    name
  }
}
```

---

## Performance Tips

### 1. Use Specific Fields (Reduces Payload)

```graphql
❌ BAD: Get entire item just to access ID
query {
  items {
    id
    name
    description
    categoryId
    category { id name }
    createdAt
    updatedAt
  }
}

✅ GOOD: Only request what you need
query {
  items {
    id
    name
  }
}
```

### 2. Use Aliases for Multiple Queries (Reduce Requests)

```graphql
❌ BAD: Two separate queries
query {
  items(limit: 5) { id }
}
query {
  categories { id }
}

✅ GOOD: Single request with aliases
query {
  items: items(limit: 5) { id }
  categories: categories { id }
}
```

### 3. Use Variables (Enables Caching)

```graphql
❌ BAD: String interpolation
# Can't cache because query string changes
query { item(id: 1) { id } }
query { item(id: 2) { id } }

✅ GOOD: Variables
# Same query string, different variables (cacheable)
query GetItem($id: Int!) { item(id: $id) { id } }
// vars: { "id": 1 }
// vars: { "id": 2 }
```

---

**Happy querying! 🚀**
