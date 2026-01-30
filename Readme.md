# API Demo

A simple REST API built with Node.js, Express, and TypeScript, using SQLite for data persistence.

## Features

- **RESTful Endpoints**: Full CRUD operations for Items.
- **Bulk Operations**: Support for bulk create, update, and delete.
- **Custom ORM**: Lightweight Data Mapper implementation.
- **SQLite**: SQL database engine.

## Getting Started

### Prerequisites

- Node.js (v24)
- npm

### Installation

```bash
npm install
```

### Running the API

Start the development server:

```bash
npm run dev
```

The server will start on `http://localhost:3001`.

### API Testing

A [.rest](.rest) file is included for testing endpoints. Use [REST Client](https://marketplace.visualstudio.com/items?itemName=humao.rest-client) extension for VS Code to execute these requests directly.

## API Endpoints

Base URL: `/rest`

### Items

| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `GET` | `/items` | List all items |
| `GET` | `/items/:id` | Get item by ID |
| `POST` | `/items` | Create new item(s) (accepts object or array) |
| `PUT` | `/items/:id` | Update an item |
| `PUT` | `/items` | Bulk update items (expects array of objects with `id`) |
| `DELETE` | `/items/:id` | Delete an item |
| `DELETE` | `/items` | Bulk delete items (expects array of `{ id }`) |
