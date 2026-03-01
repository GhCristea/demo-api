open Bun.Test

describe("ItemService - findById", () => {
  test("returns item on success", () => {
    let svc = ItemService.mock()
    expect(svc.findById(1))->toEqual(Ok(Fixtures.mockItem))
  })

  test("returns NotFound for missing id", () => {
    let svc = Fixtures.notFoundItemSvc()
    expect(svc.findById(99))->toEqual(Error(AppError.NotFound("Item 99 not found")))
  })
})

describe("ItemService - insert", () => {
  test("returns created item", () => {
    let svc   = ItemService.mock()
    let input: Schema.Items.insertRow = { name: "New", description: None, categoryId: 1 }
    expect(svc.insert(input))->toEqual(Ok(Fixtures.mockItem))
  })

  test("propagates DB error", () => {
    let svc   = Fixtures.dbErrorItemSvc()
    let input: Schema.Items.insertRow = { name: "New", description: None, categoryId: 1 }
    expect(svc.insert(input))->toEqual(Error(AppError.Internal("DB error")))
  })

  test("propagates validation error", () => {
    let svc   = Fixtures.validationErrorItemSvc()
    let input: Schema.Items.insertRow = { name: "New", description: None, categoryId: 1 }
    expect(svc.insert(input))->toEqual(Error(AppError.ValidationError(["name is required"])))
  })
})

describe("ItemService - deleteMany", () => {
  test("ok on empty list", () => {
    expect(ItemService.mock().deleteMany([]))->toEqual(Ok(()))
  })

  test("propagates first error", () => {
    let svc = Fixtures.notFoundItemSvc()
    expect(svc.deleteMany([1, 2, 3]))
    ->toEqual(Error(AppError.NotFound("Item 1 not found")))
  })
})
