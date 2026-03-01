open Bun.Test

// Inline request helper — extract to TestHelpers.res when a second HTTP test file exists
let makeRequest = (~method: string, ~url: string, ~body: option<Js.Json.t>=None): Bun.request =>
  %raw(`new Request(url, {
    method: method,
    headers: { "content-type": "application/json" },
    body: body ? JSON.stringify(body) : undefined
  })`)

let makeRegistry = (~items=ItemService.mock(), ~categories=CategoryService.mock()): ServiceRegistry.t =>
  { items, categories }

describe("GET /rest/items", () => {
  testAsync("returns 200 with items array", async () => {
    let dispatch = Router.make(makeRegistry())
    let res = await dispatch(makeRequest(~method="GET", ~url="http://localhost/rest/items"))
    expect(res->Bun.status)->toEqual(200)
  })
})

describe("GET /rest/items/:id", () => {
  testAsync("returns 200 for existing item", async () => {
    let dispatch = Router.make(makeRegistry())
    let res = await dispatch(makeRequest(~method="GET", ~url="http://localhost/rest/items/1"))
    expect(res->Bun.status)->toEqual(200)
  })

  testAsync("returns 404 for missing item", async () => {
    let dispatch = Router.make(makeRegistry(~items=Fixtures.notFoundItemSvc()))
    let res = await dispatch(makeRequest(~method="GET", ~url="http://localhost/rest/items/99"))
    expect(res->Bun.status)->toEqual(404)
  })
})

describe("POST /rest/items", () => {
  testAsync("returns 200 with created item", async () => {
    let dispatch = Router.make(makeRegistry())
    let body = Json.obj([("name", Json.str("Widget")), ("categoryId", Json.num(1.0))])
    let res = await dispatch(makeRequest(~method="POST", ~url="http://localhost/rest/items", ~body=Some(body)))
    expect(res->Bun.status)->toEqual(200)
  })

  testAsync("returns 500 on DB error", async () => {
    let dispatch = Router.make(makeRegistry(~items=Fixtures.dbErrorItemSvc()))
    let body = Json.obj([("name", Json.str("Widget")), ("categoryId", Json.num(1.0))])
    let res = await dispatch(makeRequest(~method="POST", ~url="http://localhost/rest/items", ~body=Some(body)))
    expect(res->Bun.status)->toEqual(500)
  })
})

describe("DELETE /rest/items/:id", () => {
  testAsync("returns 200 on success", async () => {
    let dispatch = Router.make(makeRegistry())
    let res = await dispatch(makeRequest(~method="DELETE", ~url="http://localhost/rest/items/1"))
    expect(res->Bun.status)->toEqual(200)
  })

  testAsync("returns 404 when item not found", async () => {
    let dispatch = Router.make(makeRegistry(~items=Fixtures.notFoundItemSvc()))
    let res = await dispatch(makeRequest(~method="DELETE", ~url="http://localhost/rest/items/99"))
    expect(res->Bun.status)->toEqual(404)
  })
})

describe("404 for unknown route", () => {
  testAsync("returns 404", async () => {
    let dispatch = Router.make(makeRegistry())
    let res = await dispatch(makeRequest(~method="GET", ~url="http://localhost/unknown"))
    expect(res->Bun.status)->toEqual(404)
  })
})
