# Quick Start: ReScript API Development

## Installation

```bash
# Install dependencies
bun install

# Verify ReScript is installed
bun exec rescript --version
```

---

## Development Workflow

### Terminal 1: Watch ReScript compilation

```bash
bun exec rescript build -w
```

This watches all `.res` files and compiles to `.res.js` on change.

### Terminal 2: Run the server

```bash
bun run src/index.res
```

Server starts at `http://localhost:3001`

---

## Testing Endpoints

### GET /items

```bash
curl http://localhost:3001/items
```

Expected:
```json
[]
```

---

### POST /items

```bash
curl -X POST http://localhost:3001/items \
  -H "Content-Type: application/json" \
  -d '{"name": "Learn ReScript", "description": "A functional language"}'
```

Expected:
```json
{
  "id": 1,
  "name": "Learn ReScript",
  "description": "A functional language",
  "createdAt": 1234567890,
  "updatedAt": 1234567890
}
```

---

### GET /items/:id

```bash
curl http://localhost:3001/items/1
```

---

### PATCH /items/:id

```bash
curl -X PATCH http://localhost:3001/items/1 \
  -H "Content-Type: application/json" \
  -d '{"name": "ReScript Mastery"}'
```

---

### DELETE /items/:id

```bash
curl -X DELETE http://localhost:3001/items/1
```

Expected: 204 No Content

---

## Common ReScript Patterns

### Pattern Matching

```rescript
switch result {
| Ok(data) => Js.log(data)
| Error(err) => Js.error(err)
}
```

### Async/Await

```rescript
let fetchData = async (): promise<data> => {
  let response = await fetch(url)
  let json = await response->json()
  json->Promise.resolve
}
```

### Option Type (for nullable values)

```rescript
let name: option<string> = Some("John")

switch name {
| Some(n) => Js.log(n)
| None => Js.log("No name")
}
```

### Result Type (for error handling)

```rescript
let parse = (json: string): result<Item.t, string> => {
  try {
    let obj = Js.Json.parseExn(json)
    Ok(obj)
  } catch {
  | _ => Error("Invalid JSON")
  }
}
```

---

## Adding a New Endpoint

### 1. Add schema to `src/core/schemas/Schemas.res`

```rescript
let newResourceSchema = object(o =>
  o->field("name", string())
)

let parseNewResourceInput = (json: string): result<NewResource.createInput, array<string>> => {
  try {
    let parsed = Js.Json.parseExn(json)
    newResourceSchema->parseWith(parsed, json)
  } catch {
  | _ => Error(["Invalid JSON"])
  }
}
```

### 2. Add handler to `src/interface/rest/ItemsController.res`

```rescript
let create = async (req: BunServer.request, _params: Js.Dict.t<string>): promise<BunServer.response> => {
  let body = await readBody(req)
  let parseResult = Schemas.parseNewResourceInput(body)
  switch parseResult {
  | Ok(input) =>
    let result = await ItemService.default.create(input)
    switch result {
    | Ok(item) => BunServer.json(~status=201, item)->Promise.resolve
    | Error(err) => AppError.toResponse(err)->Promise.resolve
    }
  | Error(errors) =>
    AppError.toResponse(AppError.ValidationError(errors))->Promise.resolve
  }
}
```

### 3. Add route to `src/interface/rest/Router.res`

```rescript
let matchRoute = (method: string, path: string): option<matchedRoute> => {
  switch (method, path) {
  | ("POST", "/newresources") => Some({handler: ItemsController.create, params: Js.Dict.empty()})
  | ...
  }
}
```

### 4. Update `src/core/services/ItemService.res`

```rescript
type deps = {
  ...,
  createNewResource: NewResource.createInput => promise<result<NewResource.t, AppError.t>>,
}
```

---

## Debugging

### Enable console logging

```rescript
Js.log("Debug message")
Js.log2("Key:", value)
Js.error("Error message")
```

### Check compiled JavaScript

The `.res.js` files are generated alongside `.res` files. Look at them to understand what's happening.

```bash
# Example: look at compiled ItemsController
cat src/interface/rest/ItemsController.res.js
```

---

## Troubleshooting

### "Cannot find module BunServer"

**Solution**: Run `bun exec rescript build` to compile all files.

### "Type mismatch: string expected int"

**Solution**: ReScript's type system is strict. Check the function signature and provide the correct type.

### "Switch not exhaustive"

**Solution**: You're missing a pattern case. The compiler is helping you! Add the missing case.

### "JSON serialization failing"

**Solution**: Make sure all values are properly converted to JSON types:

```rescript
Js.Json.object_(Js.Dict.fromArray([|
  ("name", Js.Json.string(item.name)),
  ("id", Js.Json.number(Int.toFloat(item.id))),
|]))
```

---

## Production Build

```bash
# Compile to JavaScript
bun exec rescript build

# Run compiled server
bun dist/index.js
```

---

## Resources

- **ReScript Docs**: https://rescript-lang.org/docs/manual/latest
- **rescript-schema**: https://github.com/zth/rescript-schema
- **Bun Docs**: https://bun.sh/docs
- **Project README**: Check `MIGRATION.md` for architecture details

---

## Common Commands

```bash
# Format all ReScript files
bun exec rescript format -all

# Check formatting
bun exec rescript format -all -check

# Compile (one-time)
bun exec rescript build

# Watch and compile
bun exec rescript build -w

# Run development server
bun run src/index.res

# Clean compiled files
bun exec rescript clean
```

---

**Happy coding! 🚀**
