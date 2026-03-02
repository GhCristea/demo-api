# demo-api

A zero-dependency REST API built with **Bun** + **ReScript**. SQLite via `bun:sqlite`. No Express, no ORM, no TypeScript.

## Stack

| Layer | Technology |
| :--- | :--- |
| Runtime | [Bun](https://bun.sh) |
| Language | [ReScript 11](https://rescript-lang.org) |
| Validation | [rescript-schema](https://github.com/DZakh/rescript-schema) |
| Database | SQLite via `bun:sqlite` |
| HTTP | `Bun.serve` (built-in) |

## Architecture

```
src/
  bindings/Bun.res          # FFI: serve, URL, searchParams, sqlite
  core/
    AppError.res            # error variants + toResponse
    Result.res              # ROP combinators: map, flatMap, fromOption
    Item.res                # type t + toJson + fromRow
    Category.res            # type t + toJson + fromRow
    Schemas.res             # rescript-schema validation, S.union for poly POST body
  db/
    Schema_.res             # table definitions — source of truth (rescript-sql inspired)
    Schema.res              # typed row/insert/replace shapes
    Db.res                  # open bun:sqlite + run migrations
    ItemRepo.res            # findAll(search,limit), findById, insert, insertMany,
                            # replace, replaceMany, delete, deleteMany
    CategoryRepo.res        # findAll, findByItemId
  api/
    ItemService.res         # DI record wired to ItemRepo
    ServiceRegistry.res     # single init point — no db threading at call sites
    ItemsController.res     # uniform handler type, -> pipelines
    Router.res              # /rest prefix, pattern match, longest-match ordering
    Server.res              # Bun.serve + SIGINT graceful shutdown
  Index.res                 # db → registry → server
```

## Getting Started

### Prerequisites

- [Bun](https://bun.sh) ≥ 1.1

### Install

```bash
bun install
```

### Dev

```bash
bun run dev
```

Server starts on `http://localhost:3001`.

### Build

```bash
bun run build   # rescript build -to-js
bun run start   # bun dist/index.js
```

## Environment Variables

| Variable | Default | Description |
| :--- | :--- | :--- |
| `PORT` | `3001` | HTTP port |
| `DB_PATH` | `:memory:` | SQLite file path — set to a file path to persist data |

## API Testing

A [.rest](.rest) file is included. Use the [REST Client](https://marketplace.visualstudio.com/items?itemName=humao.rest-client) VS Code extension to execute requests directly.

## API Endpoints

Base URL: `http://localhost:3001/rest`

### Items

| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `GET` | `/items` | List all items. Supports `?search=` (matches category name) and `?limit=` |
| `GET` | `/items/:id` | Get item by ID |
| `GET` | `/items/:id/categories` | Get the category for an item |
| `POST` | `/items` | Create item(s) — accepts single `{}` or array `[]` |
| `PUT` | `/items/:id` | Full replace an item (description → null if omitted) |
| `PUT` | `/items` | Bulk full replace — expects `[{id, name, categoryId, description?}]` |
| `DELETE` | `/items/:id` | Delete an item |
| `DELETE` | `/items` | Bulk delete — expects `[{id}]` |

### Categories

| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `GET` | `/items/:id/categories` | Get the category associated with item `:id` |

### Sample Category Seeds

| id | name | description |
| :--- | :--- | :--- |
| 1 | `electronics` | Consumer electronics and gadgets |
| 2 | `clothing` | Apparel and accessories |
| 3 | `books` | Physical and digital books |
| 4 | `home` | Home and garden supplies |
| 5 | `sports` | Sporting goods and outdoor equipment |

## Data Model

### categories

| Column | Type | Constraints |
| :--- | :--- | :--- |
| `id` | INTEGER | PK, AUTOINCREMENT |
| `name` | TEXT | NOT NULL, UNIQUE |
| `description` | TEXT | nullable |
| `createdAt` | REAL | NOT NULL, default now |
| `updatedAt` | REAL | NOT NULL, default now |

### items

| Column | Type | Constraints |
| :--- | :--- | :--- |
| `id` | INTEGER | PK, AUTOINCREMENT |
| `name` | TEXT | NOT NULL |
| `description` | TEXT | nullable |
| `categoryId` | INTEGER | NOT NULL, FK → categories(id) |
| `createdAt` | REAL | NOT NULL, default now |
| `updatedAt` | REAL | NOT NULL, default now |

## FP Patterns

- **Railway-Oriented Programming** — every handler is a `->` pipeline over `result<'a, AppError.t>`
- **Errors as data** — `AppError.t` variants, no exceptions in business logic
- **Schema = type** — `S.Output.t<typeof schema>` eliminates duplicate type definitions
- **DI via records** — swap `ItemService.repo` for a mock record in tests, no framework needed
- **Single serializer** — `Item.toJson` and `Category.toJson` are the only serialization points
- **Transactions as higher-order functions** — `inTransaction(db, f)` wraps any bulk op
